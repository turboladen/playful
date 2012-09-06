require 'nori'
require 'open-uri'

module UPnP
  class ControlPoint
    class Base
      def initialize
        Nori.configure do |config|
          config.convert_tags_to { |tag| tag.to_sym }
        end
      end

      protected

      def get_description(location)
        Nori.parse(open(location).read)
      end

      def build_url(url_base, scpdurl)
        if url_base.end_with?('/') && scpdurl.start_with?('/')
          scpdurl.sub!('/', '')
        end

        url_base + scpdurl
      end
    end
  end
end
