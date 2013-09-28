require "selenium-webdriver"
require "nokogiri"

module IsTheInternet
  module Page
    class Capture

      include Sidekiq::Worker

      sidekiq_options({retry: 3, unique: :all, expiration: 1296000}) # 2 week expiration!

      sidekiq_retry_in do |count|
        60 * (count + 1)
      end

      sidekiq_retries_exhausted do |msg|
        _error("REMOVING: #{msg['args'][0]}")
      end


      FORCE_ALL_CAPTURE ||= false

      def perform(url=nil,force=[])
        puts "URL: #{url}"
        @url, @force_process = url, [ force || [] ].flatten

        capture!
        raise @_error if @_error.present? # Let sidekiq know something happened

        uri.to_s
      end

      # Push a URL into the queue if not previously scraped
      def push_to_queue(urls=[])
        urls = [urls].flatten.compact
        return if urls.blank?

        urls.each do |href|
          begin
            u = Addressable::URI.parse(href)
            IsTheInternet::Page::Capture.perform_async(u.to_s)
            _debug("Added to queue: #{u}", 2, [web_page])

          rescue => err
            _error("Error queuing #{href} => #{err}", 1, [web_page])
            nil # Just skip if an error occurs
          end
        end
      end


    protected

      # Create driver connection
      def driver(b=:remote,o=nil)
        o ||= {url: 'http://localhost:9134'}
        @driver ||= Selenium::WebDriver.for(b,o)
      end

      # Stop the driver and remove the association
      def stop_driver
        @driver.quit rescue nil
        @driver = nil
      end

      # Track if error
      def error!(e); @_error = e; end

      # Parse URL
      def uri
        @uri ||= Addressable::URI.parse(@url) rescue false
      end

      # Check blacklist
      def blacklisted?
        IsTheInternet::Page::Blacklist.match?(uri)
      end

      # Parse URL host
      def uri_host
        return @uri_host unless @uri_host.blank?
        if uri.present?
          p = uri.host.gsub(/\Awww\./, '').downcase rescue ''
        end
        @uri_host = (p.blank? ? '' : p)
      end

      # Parse URL path
      def uri_path
        return @uri_path unless @uri_path.blank?
        if uri.present?
          p = (uri.path || '').downcase rescue ''
          p << "?#{uri.query}" if uri.query.present?
          p << "##{uri.fragment}" if uri.fragment.present?
        end
        @uri_path = (p.blank? ? '/' : p)
      end

      # Find or create the WebSite
      def web_site
        return @web_site unless @web_site.blank?
        @web_site = WebSite.where('LOWER(host_url) = ?', uri_host.downcase).first rescue nil
        @web_site ||= WebSite.new(url: uri.to_s, host_url: uri_host)

        if @web_site.new_record?
          # scrape robots
          @web_site.save
        end

        @web_site
      end

      # Find or create the WebPage
      def web_page
        return @web_page unless @web_page.blank?
        @web_page = web_site.web_pages.where('LOWER(path) = ?', uri_path.downcase).first rescue nil
        @web_page ||= web_site.web_pages.build(path: uri_path, url: uri.to_s)
        
        if @web_page.new_record?
          # We need to call the page to get correct status, headers, etc. WebDriver does not support this.
          begin
            io = open(uri.to_s, read_timeout: 15, "User-Agent" => CRAWLER_USER_AGENT, allow_redirections: :all)
            raise "Invalid content-type" unless io.content_type.match(/text\/html/i)

            # Additional information
            @web_page.assign_attributes(
              headers: io.meta.to_hash,
              base_uri: io.base_uri.to_s, # redirect?
              last_modified_at: io.last_modified,
              charset: io.charset,
              page_status: io.status[0],
              available: true
            )
          rescue => err # OpenURI::HTTPError => err
            @web_page.update_attribute(:available, false)
            raise err.to_s
          end

          @web_page.save
        end

        @web_page
      end

      # Temporary File Name
      def tmp_filename
        "#{APP_ROOT}/tmp/#{web_page.id}.png"
      end

      # Process to RGB color (255)
      def rgb(i=0)
        (@q18 || i > 255 ? ((255*i)/65535) : i).round
      end

      def read_page_html
        @html ||= open(uri.to_s, read_timeout: 15, "User-Agent" => CRAWLER_USER_AGENT)
      end


      # -----------------------------------------------------------------------

      # Mark web page as new
      # def capture_none
      #   web_page.step!(:none)
      # end

      # Mark web page as new
      def capture_complete
        web_page.step!(:complete)
      end

      # Capture and save screenshot
      def capture_screenshot
        begin
          driver.manage.window.resize_to(1280, 800)
          driver.navigate.to(web_page.base_uri)
          driver.save_screenshot(tmp_filename)
          web_page.screenshot = open(tmp_filename)
          raise "Unable to screenshot." unless web_page.step!(:screenshot)
          _debug("...done!", 1, [web_page])
        rescue => err
          raise err
        ensure
          stop_driver rescue nil
        end
      end


      # Process the current web page for colors
      def capture_process
        raise "Screenshot not found." if web_page.screenshot_file_size.blank? || web_page.screenshot_file_size < 1

        color_palette = web_page.color_palette rescue nil
        color_palette ||= web_page.build_color_palette

        # --- Dominant Color & Palette ---
        img = Magick::ImageList.new
        img_file = File.open(tmp_filename, "r") if File.exists?(tmp_filename)
        img_file ||= open(web_page.screenshot.url(:pixel), read_timeout: 5, "User-Agent" => CRAWLER_USER_AGENT)
        img.from_blob(img_file.read)
        img.delete_profile('*')
        palette = img.quantize(10).color_histogram.sort{|a,b| b.last <=> a.last}
        primary = palette[0][0]

        color_palette.assign_attributes({
          dominant_color: [rgb(primary.red), rgb(primary.green), rgb(primary.blue)],
          dominant_color_red: rgb(primary.red),
          dominant_color_green: rgb(primary.blue),
          dominant_color_blue: rgb(primary.green),
          color_palette: palette.map{|p,c,r| [rgb(p.red), rgb(p.green), rgb(p.blue)]}
        })
        raise "Unable to save palette colors." unless color_palette.save

        # --- Pixel ---
        img = Magick::ImageList.new
        pixel_img = web_page.screenshot.url(:pixel) if USE_S3
        pixel_img ||= File.join(APP_ROOT,web_page.screenshot.path(:pixel))
        img.from_blob(open(pixel_img, read_timeout: 5, "User-Agent" => CRAWLER_USER_AGENT).read)
        img.delete_profile('*')
        primary = img.pixel_color(0,0)

        color_palette.assign_attributes({
          pixel_color: [rgb(primary.red), rgb(primary.green), rgb(primary.blue)],
          pixel_color_red: rgb(primary.red),
          pixel_color_green: rgb(primary.blue),
          pixel_color_blue: rgb(primary.green)
        })
        raise "Unable to save pixel color." unless color_palette.save

        raise "Unable to process." unless web_page.step!(:process)
        _debug("...done!", 1, [web_page])
      end


      # Scrape the current web page
      def capture_scrape
        io = read_page_html
        io.class_eval { attr_accessor :original_filename, :content_type }
        io.original_filename = [File.basename(web_page.filename), "html"].join('.')
        io.content_type = 'text/html'
        web_page.html_page = io

        raise "Unable to scrape." unless web_page.step!(:scrape)
        _debug("...done!", 1, [web_page])
      end


      # Parse the current page for additional links to add into the queue
      def capture_parse
        io = read_page_html
        page = Nokogiri::HTML(io)

        web_page.title = page.css('title').to_s
        web_page.meta_tags = page.css('meta').map{|m| t = {}; m.attributes.each{|k,v| t[k] = v.to_s}; t }

        follow = page.css('meta[name="robots"]')[0].attributes['content'].to_s rescue 'index,follow'
        unless follow.match(/nofollow/i) 
          urls = []
          page.css('a[href]').each do |h|
            href = h.attributes['href'].to_s rescue nil
            next if href.blank? || !href.match(/^http(s)?\:\/\//i) || href.match(/(jpg|jpeg|pdf|gif|png|tif|tiff|exe|zip|js|css|txt|json|doc|docx|xls|xlsx|csv|mov|mp3|tar|eps|ai|xml)$/i)
            urls << href
          end
          push_to_queue(urls.compact.uniq)
        end
        raise "Unable to parse." unless web_page.step!(:parse)
        _debug("...done!", 1, [web_page])
      end

      # Initially open the web page in WebDriver
      def verify_web_page
        raise "URL is invalid: #{@url}" if uri.blank?
        raise "Web Site is invalid: #{@url}" if web_site.blank? || web_site.new_record?
        raise "Web Page is invalid: #{@url}" if web_page.blank? || web_page.new_record?
      end

      # -----------------------------------------------------------------------

      # Capture the URL and run through the steps
      def capture!
        begin
          if blacklisted?
            _debug("Blacklisted: #{uri}", 0)
            return
          end

          _debug("Capturing #{uri.to_s}", 0, [web_page])

          if !FORCE_ALL_CAPTURE && web_page.step?(:complete) && @force_process.blank?
            _debug("Previously completed!", 1, [web_page])
            return
          end

          Timeout::timeout(120) do # 120 seconds
            # Ensure if valid web page
            verify_web_page

            # Go through each step
            WebPage::STEPS.each do |v|
              next if !FORCE_ALL_CAPTURE && web_page.step?(v) && !@force_process.include?(:all) && !@force_process.include?(v)

              n = "capture_#{v}"
              if respond_to?(n)
                _t
                _log(v.to_s.capitalize, 1, [web_page])
                send(n)
                _log("#{v.to_s.capitalize} #{_te}", 1, [web_page])
              end
            end
          end

        rescue Timeout::Error => err
          _error("Timeout error: #{err}", 1)
          error!(err)

        rescue => err
          ActiveRecord::Base.connection.reconnect! if err.to_s.match(/mysql/i)
          _error(err, 1)
          error!(err)

        ensure
          stop_driver rescue nil
          File.unlink(tmp_filename) rescue nil
        end

      end
    end
  end
end
