require 'thin'
require 'em-synchrony'
require 'rack'
require 'rack/lobster'

module Playful
  class Device

    # Multicasts discovery messages to advertise its root device, any embedded
    # devices, and any services.
    def start
      EM.synchrony do
        web_server = Thin::Server.start('0.0.0.0', 3000) do
          use Rack::CommonLogger
          use Rack::ShowExceptions

          map '/presentation' do
            use Rack::Lint
            run Rack::Lobster.new
          end
        end

        # Do advertisement
        # Listen for subscribers
      end
    end
  end
end
