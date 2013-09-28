module IsTheInternet
  module Page
    class Blacklist

      def self.add(url)
        url = address(url)
        return false if url.blank?
        UrlBlacklist.find_or_create_by_url(url: url)
      end

      def self.match?(url)
        url = address(url)
        return false if url.blank?
        !UrlBlacklist.find_by_url(url).blank?
      end


    protected

      def self.address(url)
        begin
          url = Addressable::URI.parse(url) unless url.class == Addressable::URI
          url.host.downcase.gsub(/^www\./, '')
        rescue
          nil
        end
      end

    end
  end
end
