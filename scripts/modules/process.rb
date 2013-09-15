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
          begin
            Timeout::timeout(15) do # 15 seconds
              page = PageQueue.process.first rescue nil

              # Process if something is found
              unless page.blank?
                begin
                  page.lock!

                  _debug("Processing #{page.url}", 0, [page, page.web_page])
                  _debug(page.web_page.screenshot.url(:pixel), 1, [page, page.web_page])

                  if page.web_page.process_color_palette!
                    page.step!(:process)
                  else
                    page.retry!
                  end

                  _debug("...processing done", 1, [page, page.web_page])

                rescue => err
                  _error("Process error: #{err}", 1, [page || nil])
                  page.retry!
              
                ensure
                  page.unlock! rescue nil
                  rand_sleep
                end

              # Nothing in queue. Pause for a few seconds
              else
                _debug('Process: sleep ...')
                sleep(5)
              end
            end
          rescue Timeout::Error => err
            _error("Process Timeout error: #{err}", 1, [page || nil])
            page.unlock! rescue nil
            rand_sleep
          end
        end
      end

      def rgb(i=0)
        (@q18 || i > 255 ? ((255*i)/65535) : i).round
      end
    end
  end
end
