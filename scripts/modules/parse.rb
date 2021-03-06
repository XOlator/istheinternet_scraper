module IsTheInternet
  module Page
    class Parse

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
              page = PageQueue.parse.first# rescue nil

              # Process if something is found
              unless page.blank?
                begin
                  page.lock!

                  _debug("Parsing #{page.url}", 0, [page, page.web_page])

                  if page.web_page.parse!
                    page.step!(:parse)
                  else
                    page.retry!
                  end

                  _debug("...parsing done", 1, [page, page.web_page])

                rescue => err
                  _error("Parse error: #{err}", 1, [page, page.web_page])
                  page.retry!
      
                ensure
                  page.unlock! rescue nil
                  rand_sleep
                end

              # Nothing in queue. Pause for a few seconds
              else
                _debug('Parse: sleep ...')
                sleep(5)
              end
            end
          rescue Timeout::Error => err
            _error("Parse Timeout error: #{err}", 1)
            page.unlock! rescue nil
            rand_sleep
          end
        end
      end

    end
  end
end