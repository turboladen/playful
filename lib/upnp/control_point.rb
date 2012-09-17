require 'open-uri'
require 'nori'
require 'em-websocket'
require 'log_switch'
require_relative 'ssdp'
require_relative 'control_point/service'
require_relative 'control_point/device'

begin
  require 'nokogiri'
  Nori.parser = :nokogiri if defined? ::Nokogiri
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
    extend LogSwitch
    include LogSwitch::Mixin

    attr_reader :device

    # @params [String] search_target The device(s) to control.
    # @params [Fixnum] search_count The number of times to do an SSDP search.
    def initialize(search_target, search_count=2)
      @search_target = search_target
      @search_count = search_count

      Nori.configure do |config|
        config.convert_tags_to { |tag| tag.to_sym }
      end
    end

    def start
      @stopping = false
      response_wait_time = 2
      ttl = 4

      starter = -> do
        do_search(@search_target, response_wait_time, ttl)
        @running = true
      end

      if EM.reactor_running?
        log "Joining reactor..."
        starter.call
      else
        log "Starting reactor..."
        EM.run(&starter)
      end
    end

    def stop
      @running = false
      @stopping = false

      EM.stop if EM.reactor_running?
    end

    def running?
      @running
    end

    def do_search(search_for, response_wait_time, ttl)
      searcher = SSDP.search(search_for, {
        response_wait_time: response_wait_time, ttl: ttl
      })

      EventMachine::WebSocket.start(host: '0.0.0.0', port: 8080, debug: true) do |ws|
        ws.onopen {
          ws.send "device: #{@device}"
        }
      end

      searcher.callback do
        searcher.discovery_responses.uniq.each do |response|
          extract_device response
        end
      end

      EM.add_timer(response_wait_time) do
        searcher.set_deferred_status(:succeeded)
        searcher.close_connection
      end

      EM.add_periodic_timer(5) do
        puts "Device: #{@device}"
        puts "Device devices: #{@device.devices}"
        puts "Device services: #{@device.services}"
      end

      trap_signals
    end

    def trap_signals
      trap('INT') { stop }
      trap('TERM') { stop }
    end

    def extract_device(m_search_response)
      @device = Device.new(m_search_response: m_search_response)
    end
  end
end
