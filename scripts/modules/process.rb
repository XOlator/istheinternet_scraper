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

              # img = Magick::Image.read(page.web_page.screenshot.path).first
              img = Magick::Image.read(page.web_page.screenshot.path(:pixel)).first
              img.delete_profile('*')
              primary = img.pixel_color(0,0)
              # palette = img.quantize(10).color_histogram.sort{|a,b| b.last <=> a.last}
              # primary = palette[0][0]
              # 
              color_palette = page.web_page.color_palette rescue nil
              color_palette ||= page.web_page.build_color_palette
              color_palette.assign_attributes({
                :dominant_color => [rgb(primary.red), rgb(primary.green), rgb(primary.blue)],
                :dominant_color_red => rgb(primary.red),
                :dominant_color_green => rgb(primary.blue),
                :dominant_color_blue => rgb(primary.green),
              #   :color_palette => palette.map{|p,c,r| [rgb(p.red), rgb(p.green), rgb(p.blue)]}
              })
              
              if color_palette.save
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

      def rgb(i=0)
        (@q18 || i > 255 ? ((255*i)/65535) : i).round
      end
    end
  end
end
