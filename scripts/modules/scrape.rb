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
          begin
            Timeout::timeout(15) do # 15 seconds
              page = PageQueue.scrape.first rescue nil

              # Process if something is found
              unless page.blank?
                begin
                  page.lock!

                  _debug("Scraping #{page.url}", 0, page)
                  web_page = get_webpage(page.url)

                  unless web_page.blank?
                    page.web_page = web_page

                    if page.save
                      if page.web_page.scraped?
                        page.step!(:scrape)
                        _debug("...scraping done", 1, [page, web_page])
                      else
                        page.retry!
                        _debug("...scraping error. Retrying again shortly (1).", 1, [page, web_page])
                      end
                    else
                      page.retry!
                      _debug("...scraping error. Retrying again shortly (2).", 1, [page, web_page])
                    end

                  # Web page does not exists or is not scrapable -- remove from queue
                  else
                    page.destroy rescue nil
                    _debug("...unable to scrape.", 1, page)
                  end

                rescue => err
                  _error("Scrape Error: #{err}", 1, page)
                  page.retry!
      
                ensure
                  page.unlock! rescue nil
                  rand_sleep
                end

              # Nothing in queue. Pause for a few seconds
              else
                _debug('Scrape: sleep ...')
                sleep(5)
              end
            end
          rescue Timeout::Error => err
            _error("Scrape Timeout error: #{err}", 1, [page || nil])
            page.unlock! rescue nil
            rand_sleep
          end
        end
      end

    end
  end
end