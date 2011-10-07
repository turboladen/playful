require_relative '../../core_ext/socket_patch'
require_relative '../globals'
require 'ipaddr'
require 'socket'
require 'eventmachine'

class SSDP
  class Connection < EventMachine::Connection
    include UPnP::Globals

    # @return [Array] The list of responses from the current request.
    attr_reader :responses

    def initialize ttl=TTL
      puts "ttl", ttl
      @ttl = ttl
      @responses = []
      setup_multicast_socket
    end

    def peer_info
      peer_bytes = get_peername[2, 6].unpack("nC4")
      port = peer_bytes.first
      ip = peer_bytes[1, 4].join(".")
      return ip, port
    end

    def receive_data(response)
      ip, port = peer_info
      puts "<#{self.class}> Response from #{ip}:#{port}:\n#{response}\n"
      @responses << parse(response)
    end

    # Converts the headers to a set of key-value pairs.
    #
    # @param [String] data The data to convert.
    # @return [Hash] The converted data.
    def parse(data)
      new_data = { }

      data.each_line do |line|
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
      #unless ENV["RUBY_UPNP_ENV"] == "testing"
      #  set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\000")
      #end
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, ttl)
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_TTL, ttl)
    end
  end
end
