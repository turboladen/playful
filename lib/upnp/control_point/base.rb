require 'nori'
require 'em-http-request'
require_relative 'error'
require_relative '../../upnp'


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

        t = EM::Timer.new(30) do
          http.fail(:timeout)
        end

        http.errback do |error|
          if error == :timeout
            log "<#{self.class}> Timed out getting description.  Retrying..."
            http = EM::HttpRequest.new(location).get
          else
            log "<#{self.class}> Unable to retrieve DDF from #{location}", :error
            log "<#{self.class}> Request error: #{http.error}"
            log "<#{self.class}> Response status: #{http.response_header.status}"

            description_getter.set_deferred_status(:failed)

            if ControlPoint.raise_on_remote_error
              raise ControlPoint::Error, "Unable to retrieve DDF from #{location}"
            end
          end
        end

        http.callback {
          log "<#{self.class}> HTTP callback called for #{description_getter.object_id}"
          response = Nori.parse(http.response)
          description_getter.set_deferred_status(:succeeded, response)
        }
      end

      def build_url(url_base, rest_of_url)
        if url_base.end_with?('/') && rest_of_url.start_with?('/')
          rest_of_url.sub!('/', '')
        end

        url_base + rest_of_url
      end

      # @return [Nori::Parser]
      def xml_parser
        @xml_parser if @xml_parser

        options = {
          convert_tags_to: lambda { |tag| tag.to_sym }
        }

        begin
          require 'nokogiri'
          options.merge! parser: :nokogiri
        rescue LoadError
          warn "Tried loading nokogiri for XML couldn't.  This is OK, just letting you know."
        end

        @xml_parser = Nori.new(options)
      end
    end
  end
end
