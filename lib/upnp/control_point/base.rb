require 'nori'
require 'em-http-request'
require_relative 'error'

module UPnP
  class ControlPoint
    class Base
      include LogSwitch::Mixin

      def initialize
        Nori.configure do |config|
          config.convert_tags_to { |tag| tag.to_sym }
        end
      end

      protected

      def get_description(location, description_getter)
        log "<#{self.class}> Getting description with getter ID #{description_getter.object_id} for: #{location}"
        http = EM::HttpRequest.new(location).get

        http.errback {
          log "<#{self.class}> Unable to retrieve DDF from #{location}", :error
          log "<#{self.class}> Connection count: #{EM.connection_count}"
          log "<#{self.class}> Error from request: #{http.error}"
          raise ControlPoint::Error, "Unable to retrieve DDF from #{location}"
        }

        http.callback {
          log "<#{self.class}> HTTP callback called..."
          response = Nori.parse(http.response)
          description_getter.set_deferred_status(:succeeded, response)
        }
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
