module IsTheInternet
  module Page
    class Process

      def initialize(attrs={})
        @attrs = attrs
        @running = true
      end

      def stop
        @running = false
      end

      def run
        @running = true
        
        while @running
          page = PageQueue.process.first rescue nil

          # Process if something is found
          unless page.blank?
            begin
              page.lock!

              _debug("Processing #{page.url}")

              img = Magick::Image.read(page.web_page.screenshot.path).first
              img.delete_profile('*')
              palette = img.quantize(10).color_histogram.sort{|a,b| b.last <=> a.last}
              primary = palette[0][0]

              color_palette = page.web_page.color_palette rescue nil
              color_palette ||= page.web_page.build_color_palette
              color_palette.assign_attributes({
                :dominant_color => [primary.red, primary.green, primary.blue],
                :dominant_color_red => primary.red,
                :dominant_color_green => primary.blue,
                :dominant_color_blue => primary.green,
                :color_palette => palette.map{|p,c,r| [p.red, p.green, p.blue]}
              })
              
              if color_palette.save
                color_palette.reload
                puts color_palette.color_palette.inspect rescue "OMG ERR"
                page.step!(:process)
              else
                page.retry!
              end

              _debug("...parsing done", 1)

            rescue => err
              _debug("Parse error: #{err}", 1)
              page.retry!
              
            ensure
              page.unlock! rescue nil
            end

          # Nothing in queue. Pause for a few seconds
          else
            sleep(5)
          end
        end
      end

    end
  end
end