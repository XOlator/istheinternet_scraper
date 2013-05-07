require "headless"
require "selenium-webdriver"

module IsTheInternet
  module Page
    class Screenshot

      def initialize(attrs={})
        @attrs = attrs
        @running = true
      end

      def headless
        opts = {}
        opts[:display] = @attrs[:display] unless @attrs[:display].blank?
        @headless ||= Headless.new(opts)
      end

      def driver(b=:chrome)
        @driver ||= Selenium::WebDriver.for(b)
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
          headless.start

          while @running
            page = PageQueue.screenshot.first rescue nil

            # Process if something is found
            unless page.blank?
              _debug("Screenshot #{page.url}")

              begin
                page.lock!

                fname = "#{APP_ROOT}/tmp/#{page.web_page.id}.png"

                driver.navigate.to(page.web_page.base_uri)
                # TODO : Inject script to check if window loaded, timeout after 15 seconds
                sleep(5)

                raise "Driver has crashed" if crashed?

                driver.save_screenshot(fname)
                page.web_page.screenshot = open(fname)
                driver.navigate.to('about:blank')

                # If screenshot was saved, then mark as completed
                if page.web_page.save
                  page.step!(:screenshot)
                else
                  page.retry!
                end

                _debug("...screenshot done", 1)

              rescue => err
                stop_driver
                _debug("#{Thread.current[:name] if Thread.current} Screenshot Error (1): #{err}", 1)
                page.retry!
              
              ensure
                File.unlink(fname) rescue nil
                page.unlock! rescue nil
              end

            # Nothing in queue. Pause for a few seconds
            else
              # _debug('.')
              sleep(5)
            end
          end

        rescue => err
          _debug("#{Thread.current[:name] if Thread.current} Screenshot Error (2): #{err}")
        
        ensure
          driver.quit rescue nil
          headless.stop
        end
      end

    end
  end
end