require_relative '../core_ext/socket_patch'
require 'eventmachine'
require 'log_switch'

require_relative '../core_ext/to_upnp_s'
require_relative 'ssdp/error'
require_relative 'ssdp/network_constants'
require_relative 'ssdp/listener'
require_relative 'ssdp/searcher'
require_relative 'ssdp/notifier'

require_relative 'ssdp/broadcast_searcher'

module UPnP
  class SSDP
    extend LogSwitch
    include LogSwitch::Mixin
    include NetworkConstants

    self.logger.datetime_format = "%Y-%m-%d %H:%M:%S "

    # Opens a multicast UDP socket on 239.255.255.250:1900 and listens for
    # alive and byebye notifications from devices.
    #
    # @param [Fixnum] ttl The TTL to use on the UDP socket.
    # @return [Hash<Array>,UPnP::SSDP::Listener] If the EventMachine reactor is
    #   _not_ running, it returns two key/value pairs--one for
    #   alive_notifications, one for byebye_notifications.  If the reactor _is_
    #   running, it returns a UPnP::SSDP::Listener so that that object can be
    #   used however desired.  The latter method is used in UPnP::ControlPoints
    #   so that an object of that type can keep track of devices it cares about.
    def self.listen(ttl=TTL)
      alive_notifications = Set.new
      byebye_notifications = Set.new

      listener = proc do
        l = EM.open_datagram_socket(MULTICAST_IP, MULTICAST_PORT, UPnP::SSDP::Listener, ttl)
        i = 0
        EM.add_periodic_timer(5) { i += 5; log "Listening for #{i}\n"}
        l
      end

      if EM.reactor_running?
        return listener.call
      else
        EM.run do
          l = listener.call

          alive_getter = Proc.new do |notification|
            alive_notifications << notification
            EM.next_tick { l.available_responses.pop(&alive_getter) }
          end
          l.available_responses.pop(&alive_getter)

          byebye_getter = Proc.new do |notification|
            byebye_notifications << notification
            EM.next_tick { l.byebye_responses.pop(&byebye_getter) }
          end
          l.byebye_responses.pop(&byebye_getter)

          trap_signals
        end
      end

      {
        alive_notifications: alive_notifications.to_a.flatten,
        byebye_notifications: byebye_notifications.to_a.flatten
      }
    end

    # Opens a UDP socket on 0.0.0.0, on an ephemeral port, has UPnP::SSDP::Searcher
    # build and send the search request, then receives the responses.  The search
    # will stop after +response_wait_time+.
    #
    # @param [String] search_target
    # @param [Hash] options
    # @option options [Fixnum] response_wait_time
    # @option options [Fixnum] ttl
    # @option options [Fixnum] m_search_count
    # @option options [Boolean] do_broadcast_search Tells the search call to also send
    #   a M-SEARCH over 255.255.255.255.  This is *NOT* part of the UPnP spec;
    #   it's merely a hack for working with some types of devices that don't
    #   properly implement the UPnP spec.
    # @return [Array<Hash>,UPnP::SSDP::Searcher] Returns a Hash that represents the headers from the
    #   M-SEARCH response.  Each one of these can be passed in to UPnP::ControlPoint::Device.new
    #   to download the device's description file, parse it, and interact with
    #   the device's devices and/or services.  If the reactor is already running
    #   this will return a Proc that can be used as a callback.
    def self.search(search_target=:all, options={})
      response_wait_time = options[:response_wait_time] || 5
      ttl = options[:ttl] || TTL
      do_broadcast_search = options[:do_broadcast_search] || false

      searcher_options = options
      searcher_options.delete :do_broadcast_search

      responses = []
      search_target = search_target.to_upnp_s unless search_target.is_a? String

      multicast_searcher = proc do
        EM.open_datagram_socket('0.0.0.0', 0, UPnP::SSDP::Searcher, search_target,
          searcher_options)
      end

      broadcast_searcher = proc do
        EM.open_datagram_socket('0.0.0.0', 0, UPnP::SSDP::BroadcastSearcher, search_target,
          response_wait_time, ttl)
      end

      if EM.reactor_running?
        return multicast_searcher.call
      else
        EM.run do
          ms = multicast_searcher.call

          ms.discovery_responses.subscribe do |notification|
            responses << notification
          end

          if do_broadcast_search
            bs = broadcast_searcher.call

            bs.discovery_responses.subscribe do |notification|
              responses << notification
            end
          end

          EM.add_timer(response_wait_time) { EM.stop }
          trap_signals
        end
      end

      responses.flatten
    end

    def self.notify(notification_type, usn, ddf_url, valid_for_duration=1800)
      responses = []
      notification_type = notification_type.to_upnp_s unless notification_type.is_a? String

      EM.run do
        s = send_notification(notification_type, usn, ddf_url, valid_for_duration)
        EM.add_shutdown_hook { responses = s.discovery_responses }

        EM.add_periodic_timer(valid_for_duration) do
          s = send_notification(notification_type, usn, ddf_url, valid_for_duration)
        end

        trap_signals
      end

      responses
    end

    def self.send_notification(notification_type, usn, ddf_url, valid_for_duration)
      EM.open_datagram_socket('0.0.0.0', 0, UPnP::SSDP::Notifier, notification_type,
        usn, ddf_url, valid_for_duration)
    end

    private

    # Traps INT and TERM signals and stops the reactor.
    def self.trap_signals
      trap('INT') { EM.stop }
      trap('TERM') { EM.stop }
      trap("HUP")  { EM.stop } if RUBY_PLATFORM !~ /mswin|mingw/
    end
  end
end
