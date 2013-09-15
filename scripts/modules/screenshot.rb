require "selenium-webdriver"

module IsTheInternet
  module Page
    class Screenshot

      def initialize(attrs={})
        @attrs = attrs
        @running = true
      end

      def driver(b=:remote,o=nil)
        o ||= {:url => 'http://localhost:9134'}
        @driver ||= Selenium::WebDriver.for(b,o)
      end

      # Stop the driver and remove the association
      def stop_driver
        @driver.quit rescue nil
        @driver = nil
      end

      # Check if driver crashed
      # - send a command and see if it executes or not
      def crashed?
        # TODO
        false
      end

      def stop
        @running = false
      end

      def run
        @running = true

        begin
          while @running
            begin
              Timeout::timeout(25) do # 25 seconds
                page = PageQueue.screenshot.first# rescue nil

                # Process if something is found
                unless page.blank?
                  _debug("Screenshot #{page.url}", 0, page)

                  begin
                    page.lock!

                    fname = "#{APP_ROOT}/tmp/#{page.web_page.id}.png"

                    driver.navigate.to(page.web_page.base_uri)
                    raise "Driver has crashed" if crashed?

                    driver.save_screenshot(fname)
                    page.web_page.screenshot = open(fname)

                    # If screenshot was saved, then mark as completed
                    if page.web_page.save
                      page.step!(:screenshot)
                    else
                      page.retry!
                    end

                    _debug("...screenshot done", 1, [page, page.web_page])

                  rescue => err
                    _error("#{Thread.current[:name] if Thread.current} Screenshot Error (1): #{err}", 1, [page, page.web_page])
                    page.retry!
              
                  ensure
                    stop_driver
                    File.unlink(fname) rescue nil
                    page.unlock! rescue nil
                    rand_sleep
                  end

                # Nothing in queue. Pause for a few seconds
                else
                  _debug('Screenshot: sleep ...')
                  sleep(5)
                end
              end
            rescue Timeout::Error => err
              _error("Screenshot Timeout error: #{err}", 1)
              page.unlock! rescue nil
              rand_sleep
              driver.quit rescue nil
            end
          end

        rescue => err
          _error("#{Thread.current[:name] if Thread.current} Screenshot Error (2): #{err}", 0)
        
        ensure
          driver.quit rescue nil
        end
      end

    end
  end
end