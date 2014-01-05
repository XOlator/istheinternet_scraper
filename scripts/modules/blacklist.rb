module IsTheInternet
  module Page
    class Blacklist

      def self.cache; @@cache ||= []; end

      def self.add(url)
        url = address(url)
        return false if url.blank?
        UrlBlacklist.find_or_create_by_url(url: url)
      end

      def self.match?(url)
        url = address(url)
        return false if url.blank?
        return true if cache.include?(url)
        
        if !UrlBlacklist.where("url = ? OR LOCATE(url,?)", url, url).blank?
          @@cache << url
          return true
        else
          return false
        end
      end

    protected

      def self.address(url)
        begin
          url = Addressable::URI.parse(url) unless url.class == Addressable::URI
          url.host.downcase.gsub(/^www\./, '')
        rescue => err
          _debug("Blacklist: Error: #{url} #{err}")
          false
        end
      end

    end
  end
end
