require_relative '../../core_ext/socket_patch'
require 'ipaddr'
require 'socket'
require 'eventmachine'

class SSDP
  class Connection < EventMachine::Connection

    # Default broadcast address
    BROADCAST = '239.255.255.250'

    # Default multicast port
    MULTICAST_PORT = 1900

    # Default packet time to live (hops)
    TTL = 4

    def initialize ttl=TTL
      @ttl = ttl
    end

    def post_init
      setup_multicast_socket
    end

    def receive_data(data)
      p data
    end

    def setup_multicast_socket
      membership = IPAddr.new(BROADCAST).hton + IPAddr.new('0.0.0.0').hton
      ttl = [@ttl].pack 'i'

      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\000")
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, ttl)
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_TTL, ttl)
    end
  end
end
