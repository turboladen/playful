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

    # @return [Array] The list of responses from the current request.
    attr_reader :responses

    def initialize ttl=TTL
      @ttl = ttl
      @responses = []
      setup_multicast_socket
    end

    def receive_data(response)
      puts "<#{self.class}> #{response}"
      @responses << parse(response)
    end

    # Converts the headers to a set of key-value pairs.
    #
    # @param [String] data The data to convert.
    # @return [Hash] The converted data.
    def parse(data)
      new_data = { }

      data.each_line do |line|
        puts "line:", line
        line =~ /(\S*): (.*)/

        unless $1.nil?
          key = $1
          value = $2
          key = key.gsub('-', '_').downcase.to_sym
          new_data[key] = value.strip
        end
      end

      new_data
    end

    # Sets Socket options to allow for multicasting.
    def setup_multicast_socket
      membership = IPAddr.new(BROADCAST).hton + IPAddr.new('0.0.0.0').hton
      ttl = [@ttl].pack 'i'

      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\000")
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, ttl)
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_TTL, ttl)
    end

    # Gets the current "peer"'s IP and PORT.
    #
    # @return [String] A String in the form: ip:port.
    def peer
      @peer ||=
        begin
          port, ip = Socket.unpack_sockaddr_in(get_sockname)
          "#{ip}:#{port}"
        end
    end
  end
end
