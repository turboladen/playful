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

    # @param [String] search_target The device(s) to control.
    # @param [Fixnum] search_count The number of times to do an SSDP search.
    def initialize(search_target, search_count=2)
      @search_target = search_target
      @search_count = search_count
      @devices = []
      @new_device_queue = EventMachine::Queue.new
      @old_device_queue = EventMachine::Queue.new

      Nori.configure do |config|
        config.convert_tags_to { |tag| tag.to_sym }
      end
    end

    def start options={}, &blk
      @stopping = false

      options[:response_wait_time] ||= 5
      options[:m_search_count] ||= @search_count
      ttl = options[:response_wait_time] || 4

      starter = -> do
        ssdp_search_and_listen(@search_target, options)
        blk.call(@new_device_queue, @old_device_queue)
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

    def listen(ttl)
      listener = SSDP.listen(ttl)

      listener.available_responses.pop do |advertisement|
        log "<#{self.class}> Got alive #{advertisement}"
        create_device(advertisement)
      end

      listener.byebye_responses.pop do |advertisement|
        log "<#{self.class}> Got bye-bye from #{advertisement}"

        @devices.reject! do |device|
          device.usn == advertisement[:usn]
        end

        @old_device_queue << advertisement
      end
    end

    def ssdp_search_and_listen(search_for, options={})
      searcher = SSDP.search(search_for, options)

      searcher.discovery_responses.pop do |notification|
        create_device(notification)
      end

      # Do I need to do this?
      EM.add_timer(options[:response_wait_time]) do
        searcher.close_connection
        listen(options[:ttl])
      end

      EM.add_periodic_timer(5) do
        log "<#{self.class}> Time since last timer: #{Time.now - @timer_time}" if @timer_time
        log "<#{self.class}> Connections: #{EM.connection_count}"
        @timer_time = Time.now
        puts "<#{self.class}> Device count: #{@devices.size}"
        puts "<#{self.class}> Device unique: #{@devices.uniq.size}"
      end

      trap_signals
    end

    def create_device(notification)
      deferred_device = Device.new(ssdp_notification: notification)

      deferred_device.errback do |message|
        log "<#{self.class}> #{message}"
        raise ControlPoint::Error, message
      end

      deferred_device.callback do |built_device|
        log "<#{self.class}> Device created from #{notification}"

        if @devices.any? { |d| d.usn == built_device.usn }
          log "<#{self.class}> Newly created device already exists in internal list. Not adding."
        else
          log "<#{self.class}> Adding newly created device to internal list.."
          @new_device_queue.push(built_device)
          @devices << built_device
        end
      end

      deferred_device.fetch
    end

    def stop
      @running = false
      @stopping = false

      EM.stop if EM.reactor_running?
    end

    def running?
      @running
    end

    def trap_signals
      trap('INT') { stop }
      trap('TERM') { stop }
    end
  end
end
