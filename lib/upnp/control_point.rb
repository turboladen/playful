require 'open-uri'
require 'nori'
require 'log_switch'
require_relative 'ssdp'
require_relative 'control_point/service'
require_relative 'control_point/device'
require_relative 'control_point/error'


module UPnP

  # Allows for controlling a UPnP device as defined in the UPnP spec for control
  # points.
  #
  # It uses +Nori+ for parsing the description XML files, which will use +Nokogiri+
  # if you have it installed.
  class ControlPoint
    extend LogSwitch
    include LogSwitch::Mixin

    def self.config
      yield self
    end

    class << self
      attr_accessor :raise_on_remote_error
    end

    @@raise_on_remote_error ||= true

    attr_reader :devices

    # @param [String] search_target The device(s) to control.
    # @param [Hash] search_options Options to pass on to SSDP search and listen calls.
    # @option options [Fixnum] response_wait_time
    # @option options [Fixnum] m_search_count
    # @option options [Fixnum] ttl
    def initialize(search_target, search_options={})
      @search_target = search_target
      @search_options = search_options
      @search_options[:ttl] ||= 4
      @devices = []
      @new_device_channel = EventMachine::Channel.new
      @old_device_channel = EventMachine::Channel.new
    end

    # Starts the ControlPoint.  If an EventMachine reactor is running already,
    # it'll join that reactor, otherwise it'll start the reactor.
    #
    # @yieldparam [EventMachine::Channel] new_device_channel The means through
    #   which clients can get notified when a new device has been discovered
    #   either through SSDP searching or from an +ssdp:alive+ notification.
    # @yieldparam [EventMachine::Channel] old_device_channel The means through
    #   which clients can get notified when a device has gone offline (have sent
    #   out a +ssdp:byebye+ notification).
    def start &blk
      @stopping = false

      starter = -> do
        ssdp_search_and_listen(@search_target, @search_options)
        blk.call(@new_device_channel, @old_device_channel)
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
      EM.defer do
        listener = SSDP.listen(ttl)

        listener.alive_notifications.subscribe do |advertisement|
          log "<#{self.class}> Got alive #{advertisement}"

          if @devices.any? { |d| d.usn == advertisement[:usn] }
            log "<#{self.class}> Device with USN #{advertisement[:usn]} already exists."
          else
            log "<#{self.class}> Device with USN #{advertisement[:usn]} not found. Creating..."
            create_device(advertisement)
          end
        end

        listener.byebye_notifications.subscribe do |advertisement|
          log "<#{self.class}> Got bye-bye from #{advertisement}"

          @devices.reject! do |device|
            device.usn == advertisement[:usn]
          end

          @old_device_channel << advertisement
        end
      end
    end

    def ssdp_search_and_listen(search_for, options={})
      searcher = SSDP.search(search_for, options)

      searcher.discovery_responses.subscribe do |notification|
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

      deferred_device.errback do |partially_built_device, message|
        log "<#{self.class}> #{message}"
        #add_device(partially_built_device)

        if self.class.raise_on_remote_error
          raise ControlPoint::Error, message
        end
      end

      deferred_device.callback do |built_device|
        log "<#{self.class}> Device created from #{notification}"
        add_device(built_device)
      end

      deferred_device.fetch
    end

    def add_device(built_device)
      if (@devices.any? { |d| d.usn == built_device.usn }) ||
        (@devices.any? { |d| d.udn == built_device.udn })
        log "<#{self.class}> Newly created device already exists in internal list. Not adding."
      #if @devices.any? { |d| d.usn == built_device.usn }
      #  log "<#{self.class}> Newly created device (#{built_device.usn}) already exists in internal list. Not adding."
      else
        log "<#{self.class}> Adding newly created device to internal list.."
        @new_device_channel << built_device
        @devices << built_device
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

    def trap_signals
      trap('INT') { stop }
      trap('TERM') { stop }
      trap("HUP")  { stop } if RUBY_PLATFORM !~ /mswin|mingw/
    end
  end
end
