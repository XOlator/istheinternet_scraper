require "selenium-webdriver"

module IsTheInternet
  module Page
    class Capture

      include Sidekiq::Worker


      def initialize(url,force=[])
        @url = url
        @force_process = force || []
        capture!
      end


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

      # Parse URL
      def uri
        return @uri unless @uri.blank?
        @uri = Addressable::URI.parse(@url) rescue false
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
        @web_site ||= WebSite.new(url: uri, host_url: uri_host)

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
        @web_page ||= web_site.web_pages.build(path: uri_path, url: uri)
        
        if @web_page.new_record?
          # do something here?
          @web_page.save
        end

        @web_page
      end

      # -----------------------------------------------------------------------

      # Mark web page as new
      def capture_none
        web_page.step!(:none)
      end

      # Capture and save screenshot
      def capture_screenshot
        fname = "#{APP_ROOT}/tmp/#{web_page.id}.png"
        driver.save_screenshot(fname)
        web_page.screenshot = open(fname)

        raise "Unable to screenshot." unless web_page.step!(:screenshot)
        _debug("...done!", 1, [web_page])
      end

      def capture_process
        raise "Unable to process." unless web_page.step!(:process)
        _debug("...done!", 1, [web_page])
      end

      def capture_scrape
        raise "Unable to scrape." unless web_page.step!(:scrape)
        _debug("...done!", 1, [web_page])
      end

      def capture_parse
        # web_page.title = page.css('title').to_s
        # web_page.meta_tags = page.css('meta').map{|m| t = {}; m.attributes.each{|k,v| t[k] = v.to_s}; t }
        # 
        # follow = page.css('meta[name="robots"]')[0].attributes['content'].to_s rescue 'index,follow'
        # page.css('a[href]').each{|h| PageQueue::add(h.attributes['href']) } unless follow.match(/nofollow/i)

        raise "Unable to parse." unless web_page.step!(:parse)
        _debug("...done!", 1, [web_page])
      end
      

      def capture!
        begin
          Timeout::timeout(120) do # 120 seconds
            raise "URL is invalid: #{@url}" if uri.blank?
            raise "Web Site is invalid: #{@url}" if web_site.blank? || web_site.new_record?
            raise "Web Page is invalid: #{@url}" if web_page.blank? || web_page.new_record?

            _debug("Capturing #{uri}", 0, [web_page])

            driver.navigate.to(web_page.base_uri)
            # Set window size and background white

            # Go through each step
            WebPage::STEPS.each do |v|
              next if web_page.step?(v) && !@force_process.include?(v)

              n = "capture_#{v}"
              if respond_to?(n)
                _debug(v.to_s.capitalize, 1, [web_page])
                send(n)
              end
            end
          end

        rescue Timeout::Error => err
          _error("Timeout error: #{err}", 1)

        rescue => err
          _error(err, 1)

        ensure
          stop_driver rescue nil
          File.unlink(fname) rescue nil
        end

      end

    rescue => err
      _error("#{Thread.current[:name] if Thread.current} Screenshot Error (2): #{err}", 0)
    
    ensure
      stop_driver rescue nil
    end
  end
end