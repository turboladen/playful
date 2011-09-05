require_relative '../core_ext/socket_patch'
require 'ipaddr'
require 'socket'
require 'eventmachine'

require_relative 'ssdp/listener'
require_relative 'ssdp/searcher'

class SSDP

  # Default broadcast address
  BROADCAST = '239.255.255.250'

  # Default multicast port
  MULTICAST_PORT = 1900

  # Default TTL
  TTL = 4

  # Simply open a multicast UDP socket and listen for data.
  def self.listen(ttl=TTL)
    EM.run do
      EM.open_datagram_socket(BROADCAST, MULTICAST_PORT, SSDP::Listener, ttl)
      i = 0
      EM.add_periodic_timer(1) { i += 1; puts "#{i}\r"}
      trap_signals
    end
  end

  # Opens a UDP socket on 0.0.0.0, on an ephemeral port, has SSDP::Searcher
  # build and send the search request, then receives the responses.  The search
  # will stop after +response_wait_time+.
  #
  # @param [String] search_target
  # @param [Fixnum] response_wait_time
  # @param [Fixnum] ttl
  # @param [Array] An Array of all of the responses received from the request.
  def self.search(search_target="ssdp:all", response_wait_time=5, ttl=TTL)
    responses = []

    EM.run do
      s = EM.open_datagram_socket('0.0.0.0', 0, SSDP::Searcher, search_target,
        response_wait_time, ttl)
      EM.add_shutdown_hook { responses = s.responses }
      EM.add_timer(response_wait_time) { EM.stop }
      trap_signals
    end

    responses
  end

  def self.trap_signals
    trap 'INT' do
      EM.stop
    end

    trap 'TERM' do
      EM.stop
    end
  end
end
