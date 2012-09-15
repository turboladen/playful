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
    include NetworkConstants

    self.logger.datetime_format = "%Y-%m-%d %H:%M:%S "

    # Simply open a multicast UDP socket and listen for data.
    #def self.listen(ttl=TTL)
    #  EM.run do
    #    EM.open_datagram_socket(MULTICAST_IP, MULTICAST_PORT, UPnP::SSDP::Listener, ttl)
    #    i = 0
    #    EM.add_periodic_timer(1) { i += 1; print "listening for \b#{i}"}
    #    trap_signals
    #  end
    #end

    # Opens a UDP socket on 0.0.0.0, on an ephemeral port, has UPnP::SSDP::Searcher
    # build and send the search request, then receives the responses.  The search
    # will stop after +response_wait_time+.
    #
    # @param [String] search_target
    # @param [Fixnum] response_wait_time
    # @param [Fixnum] ttl
    # @param [Fixnum] search_count The number of times to send the search request.
    # @param [Boolean] do_broadcast_search Tells the search call to also send
    #   a M-SEARCH over 255.255.255.255.  This is *NOT* part of the UPnP spec;
    #   it's merely a hack for working with some types of devices that don't
    #   properly implement the UPnP spec.
    # @param [Array] An Array of all of the responses received from the request.
    def self.search(search_target=:all, response_wait_time=3, ttl=TTL, search_count=2,
      do_broadcast_search=false)
      responses = []
      search_target = search_target.to_upnp_s unless search_target.is_a? String

      connect = proc do
        tmp_responses = []

        search_count.times do
          tmp_responses << EM.open_datagram_socket('0.0.0.0', 0, UPnP::SSDP::Searcher, search_target,
            response_wait_time, ttl)

          if do_broadcast_search
            EM.open_datagram_socket('0.0.0.0', 0, UPnP::SSDP::BroadcastSearcher, search_target,
              response_wait_time, ttl)
          end
        end

        tmp_responses.flatten
      end

      if EM.reactor_running?
        return connect.call
      else
        EM.run do
          s = connect.call
          EM.add_shutdown_hook { responses = *s.map(&:discovery_responses).flatten }
          EM.add_timer(response_wait_time) { EM.stop }
          trap_signals
        end

      end

      responses
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

    # Traps INT and TERM signals and stops the reactor.
    def self.trap_signals
      trap 'INT' do
        EM.stop
      end

      trap 'TERM' do
        EM.stop
      end
    end
  end
end
