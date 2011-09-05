require_relative '../core_ext/socket_patch'
require 'ipaddr'
require 'socket'
require 'eventmachine'

require_relative 'ssdp/discoverer'
require_relative 'ssdp/searcher'

class SSDP

  # Default broadcast address
  BROADCAST = '239.255.255.250'

  # Default multicast port
  MULTICAST_PORT = 1900

  # Default TTL
  TTL = 4

  # Simply open a multicast UDP socket and listen for data.
  def self.discover(ttl=TTL)
    EM.run do
      EM.open_datagram_socket(BROADCAST, MULTICAST_PORT, SSDP::Discoverer, ttl)
      i = 0
      EM.add_periodic_timer(1) { i += 1; puts "#{i}\r"}
      trap_signals
    end
  end

  # Builds the search request from the given parameters, opens a UDP socket on
  # 0.0.0.0, on an ephemeral port, SSDP::Searcher sends the request and receives
  # the responses.  The search will stop after +response_wait_time+.
  #
  # @param [String] search_target
  # @param [Fixnum] response_wait_time
  # @param [Fixnum] ttl
  # @param [Array] An Array of all of the responses received from the request.
  def self.search(search_target="ssdp:all", response_wait_time=5, ttl=TTL)
    search = <<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: #{BROADCAST}:#{MULTICAST_PORT}\r
MAN: "ssdp:discover"\r
MX: #{response_wait_time}\r
ST: #{search_target}\r
\r
    MSEARCH

    responses = []

    EM.run do
      EM.open_datagram_socket(BROADCAST, MULTICAST_PORT, SSDP::Discoverer, ttl)
      s = EM.open_datagram_socket('0.0.0.0', 0, SSDP::Searcher, search, ttl)
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
