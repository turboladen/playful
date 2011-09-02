require_relative '../core_ext/socket_patch'
require 'ipaddr'
require 'socket'
require 'eventmachine'

require_relative '../ssdp/discoverer'
require_relative '../ssdp/searcher'

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
      trap_signals
    end
  end

  def self.search(search_target="ssdp:all", response_delay=1, ttl=TTL)
    search = <<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: #{BROADCAST}:#{MULTICAST_PORT}\r
MAN: "ssdp:discover"\r
MX: #{response_delay}\r
ST: #{search_target}\r
\r
    MSEARCH

    EM.run do
      EM.add_periodic_timer(5) do
        EM.open_datagram_socket(BROADCAST, MULTICAST_PORT, SSDP::Searcher, search, ttl)
      end
      trap_signals
    end
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
