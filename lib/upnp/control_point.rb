require 'open-uri'
require 'nori'
require 'thin'
require 'rack'
require 'rack/lobster'
require 'em-websocket'
require_relative 'ssdp'
require_relative 'control_point/service'
require_relative 'control_point/device'

begin
  require 'nokogiri'
rescue LoadError
  # Fail quietly
end

module UPnP

  # Allows for controlling a UPnP device as defined in the UPnP spec for control
  # points.
  #
  # It uses +Nori+ for parsing the description XML files, which will use +Nokogiri+
  # if you have it installed.
  class ControlPoint
    attr_reader :devices
    attr_reader :services

    def initialize(ip='0.0.0.0', port=0)
      @ip = ip
      @port = port
      @devices = []
      @services = []
      Nori.parser = :nokogiri if defined? ::Nokogiri
      Nori.configure do |config|
        config.convert_tags_to { |tag| tag.to_sym }
      end
    end

    def start
      response_wait_time = 2

      #search_for ="ssdp:all"
      search_for ="upnp:rootdevice"
      #search_for = "uuid:100330fe-5d3e-4a5e-98c7-0000a6504b8c-Camera-5::urn:schemas-pelco-com:service:VideoOutput:1"
      #search_for = "uuid:100330fe-5d3e-4a5e-98c7-0000a6504b8c-Camera-2"

      if EM.reactor_running?
        puts "joining reactor..."

        do_search(search_for, response_wait_time, 4)
        web_server
      else
        EM.run do
          do_search(search_for, response_wait_time, 4)
          web_server
        end
      end
    end

    def web_server
      Thin::Server.start('0.0.0.0', 3000) do
        use Rack::CommonLogger
        use Rack::ShowExceptions

        map "/lobster" do
          use Rack::Lint
          run Rack::Lobster.new
        end
      end
    end

    def do_search(search_for, response_wait_time, ttl)
      searcher = EM.open_datagram_socket(@ip, 0, UPnP::SSDP::Searcher,
        search_for, response_wait_time, 4)

      EventMachine::WebSocket.start(host: '0.0.0.0', port: 8080, debug: true) do |ws|
        ws.onopen {
          ws.send "services: #{@services}"
        }
      end

      searcher.callback do
        extract_devices_and_services(searcher.responses)
      end

      EM.add_timer(response_wait_time) do
        searcher.set_deferred_status(:succeeded)
        searcher.close_connection
      end

      EM.add_periodic_timer(5) do
        puts "Device count: #{@devices.size}"
        puts "Service count: #{@services.size}"
      end

      SSDP.trap_signals
    end

    def extract_devices_and_services(new_devices)
      @devices = new_devices.map { |device| Device.new(device) }

      require 'pp'
      puts "last device"
      pp @devices.last
    end
  end
end
