module IsTheInternet
  module Page
    class Scrape
  
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
          page = PageQueue.scrape.first rescue nil

          # Process if something is found
          unless page.blank?
            begin
              page.lock!

              _debug("Scraping #{page.url}")
              web_page = get_webpage(page.url)

              unless web_page.blank?
                page.web_page = web_page
          
                if page.save
                  if web_page.scraped?
                    page.step!(:scrape)
                    _debug("...scraping done", 1)
                  else
                    page.retry!
                    _debug("...scraping error. Retrying again shortly (1).", 1)
                  end
                else
                  puts page.errors.inspect
                  page.retry!
                  _debug("...scraping error. Retrying again shortly (2).", 1)
                end

              # Web page does not exists or is not scrapable -- remove from queue
              else
                page.destroy rescue nil
                _debug("...unable to scrape.", 1)
              end

            rescue => err
              _debug("Scrape Error: #{err}", 1)
              page.retry!
      
            ensure
              page.unlock! rescue nil
            end

          # Nothing in queue. Pause for a few seconds
          else
            # _debug('.')
            sleep(5)
          end
        end
      end

    end
  end
end