require_relative '../core_ext/socket_patch'
require 'eventmachine'
require 'log_switch'

require_relative '../core_ext/to_upnp_s'
require_relative 'ssdp/error'
require_relative 'ssdp/network_constants'
require_relative 'ssdp/listener'
require_relative 'ssdp/searcher'
require_relative 'ssdp/notifier'

module UPnP
  class SSDP
    extend LogSwitch
    include NetworkConstants

    self.logger.datetime_format = "%Y-%m-%d %H:%M:%S "

    # Simply open a multicast UDP socket and listen for data.
    #def self.listen(ttl=TTL)
    #  EM.run do
    #    EM.open_datagram_socket(BROADCAST, MULTICAST_PORT, UPnP::SSDP::Listener, ttl)
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
    # @param [Array] An Array of all of the responses received from the request.
    def self.search(search_target=:all, response_wait_time=3, ttl=TTL)
      responses = []
      search_target = search_target.to_upnp_s unless search_target.is_a? String

      EM.run do
        s = EM.open_datagram_socket('0.0.0.0', 0, UPnP::SSDP::Searcher, search_target,
          response_wait_time, ttl)
        EM.add_shutdown_hook { responses = s.responses }
        EM.add_timer(response_wait_time) { EM.stop }
        trap_signals
      end

      responses
    end

    def self.notify(notification_type, usn, ddf_url, valid_for_duration=1800)
      responses = []
      notification_type = notification_type.to_upnp_s unless notification_type.is_a? String

      EM.run do
        s = send_notification(notification_type, usn, ddf_url, valid_for_duration)
        EM.add_shutdown_hook { responses = s.responses }

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
