require 'open-uri'
require 'nori'
require 'em-websocket'
require 'log_switch'
require_relative 'ssdp'
require_relative 'control_point/service'
require_relative 'control_point/device'
require_relative 'control_point/error'

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

    attr_reader :devices

    # @params [String] search_target The device(s) to control.
    # @params [Fixnum] search_count The number of times to do an SSDP search.
    def initialize(search_target, search_count=2)
      @search_target = search_target
      @search_count = search_count
      @devices = []
      @device_queue = EventMachine::Queue.new

      Nori.configure do |config|
        config.convert_tags_to { |tag| tag.to_sym }
      end
    end

    def start
      @stopping = false
      response_wait_time = 5
      ttl = 4

      starter = -> do
        @search_count.times do
          do_search(@search_target, response_wait_time, ttl)
        end

        EM.add_periodic_timer(15) do
          do_search(@search_target, response_wait_time, ttl)
        end

        yield @device_queue if block_given?

        @running = true
      end

      if EM.reactor_running?
        log "<#{self.class}> Joining reactor..."
        starter.call
      else
        log "<#{self.class}> Starting reactor..."
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

      searcher.errback do
        msg = "SSDP search failed."
        log "<#{self.class}> #{msg}"
        raise ControlPoint::Error, msg
      end

      searcher.callback do
        log "<#{self.class}> Unique search responses: #{searcher.discovery_responses.uniq.size}"

        EM::Iterator.new(searcher.discovery_responses.uniq, searcher.discovery_responses.uniq.size).each do |m_search_response|
          deferred_device = Device.new(m_search_response: m_search_response)

          deferred_device.errback do |message|
            log "<#{self.class}> #{message}"
            raise ControlPoint::Error, message
          end

          deferred_device.callback do |built_device|
            unless @devices.any? { |d| d.usn == built_device.usn }
              @device_queue.push(built_device)
              @devices << built_device
            end
          end

          deferred_device.fetch
        end
      end

      EM.add_timer(response_wait_time) do
        searcher.set_deferred_status(:succeeded)
        searcher.close_connection
      end

      EM.add_periodic_timer(5) do
        log "<#{self.class}> Time since last timer: #{Time.now - @timer_time}" if @timer_time
        @timer_time = Time.now
        puts "<#{self.class}> Device count: #{@devices.size}"
        puts "<#{self.class}> Device unique: #{@devices.uniq.size}"
      end

      trap_signals
    end

    def trap_signals
      trap('INT') { stop }
      trap('TERM') { stop }
    end
  end
end
