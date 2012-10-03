require_relative '../../core_ext/socket_patch'
require_relative 'network_constants'
require_relative 'error'
require 'ipaddr'
require 'socket'
require 'eventmachine'


module UPnP
  class SSDP
    class MulticastConnection < EventMachine::Connection
      include UPnP::SSDP::NetworkConstants

      # @return [EventMachine::Channel] Provides subscribers with responses from
      #   their search request.
      attr_reader :discovery_responses

      # @return [EventMachine::Channel] Provides subscribers with notifications
      #   from devices that have come online (sent +ssdp:alive+ notifications).
      attr_reader :available_responses

      # @return [EventMachine::Channel] Provides subscribers with notifications
      #   from devices that have gone offline (sent +ssd:byebye+ notifications).
      attr_reader :byebye_responses

      # @param [Fixnum] ttl The TTL value to use when opening the UDP socket
      #   required for SSDP actions.
      def initialize ttl=TTL
        @ttl = ttl

        @discovery_responses = EM::Channel.new
        @available_responses = EM::Channel.new
        @byebye_responses = EM::Channel.new

        setup_multicast_socket
      end

      # Gets the IP and port from the peer that just sent data.
      #
      # @return [Array<String,Fixnum>] The IP and port.
      def peer_info
        peer_bytes = get_peername[2, 6].unpack("nC4")
        port = peer_bytes.first.to_i
        ip = peer_bytes[1, 4].join(".")

        [ip, port]
      end

      # This is the callback called by EventMachine when it receives data on the
      # socket that's been opened for this connection.  In this case, the method
      # parses the SSDP responses/notifications into Hashes and adds them to the
      # appropriate EventMachine::Channel (provided as accessor methods).  This
      # effectively means that in each Channel, you get a Hash that represents
      # the headers for each response/notification that comes in on the socket.
      #
      # @param [String] response The data received on this connection's socket.
      def receive_data(response)
        ip, port = peer_info
        SSDP.log "<#{self.class}> Response from #{ip}:#{port}:\n#{response}\n"
        parsed_response = parse(response)

        if parsed_response.has_key? :nts
          if parsed_response[:nts] == "ssdp:alive"
            @available_responses << parsed_response
          elsif parsed_response[:nts] == "ssdp:byebye"
            @byebye_responses << parsed_response
          else
            raise "Unknown NTS value: #{parsed_response[:nts]}"
          end
        elsif parsed_response[:man] && parsed_response[:man] =~ /ssdp:discover/
        else
          @discovery_responses << parsed_response
        end
      end

      # Converts the headers to a set of key-value pairs.
      #
      # @param [String] data The data to convert.
      # @return [Hash] The converted data.  Returns an empty Hash if it didn't
      #   know how to parse.
      def parse(data)
        new_data = {}

        unless data =~ /\n/
          SSDP.log "<#{self.class}> Received response as a single-line String.  Discarding."
          SSDP.log "<#{self.class}> Bad response looked like:\n#{data}"
          return new_data
        end

        data.each_line do |line|
          line =~ /(\w+):(.*)/

          unless $1.nil?
            key = $1
            value = $2
            key = key.gsub('-', '_').downcase.to_sym
            new_data[key] = value.strip
          end
        end

        new_data
      end

      # Sets Socket options to allow for multicasting.  If ENV["RUBY_UPNP_ENV"] is
      # equal to "testing", then it doesn't turn off multicast looping.
      def setup_multicast_socket
        set_membership(IPAddr.new(MULTICAST_IP).hton + IPAddr.new('0.0.0.0').hton)
        set_multicast_ttl(@ttl)
        set_ttl(@ttl)

        unless ENV["RUBY_UPNP_ENV"] == "testing"
          switch_multicast_loop :off
        end
      end

      # @param [String] membership The network byte ordered String that represents
      #   the IP(s) that should join the membership group.
      def set_membership(membership)
        set_sock_opt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
      end

      # @param [Fixnum] ttl TTL to set IP_MULTICAST_TTL to.
      def set_multicast_ttl(ttl)
        set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, [ttl].pack('i'))
      end

      # @param [Fixnum] ttl TTL to set IP_TTL to.
      def set_ttl(ttl)
        set_sock_opt(Socket::IPPROTO_IP, Socket::IP_TTL, [ttl].pack('i'))
      end

      # @param [Symbol] on_off Turn on/off multicast looping.  Supply :on or :off.
      def switch_multicast_loop(on_off)
        hex_value = case on_off
        when :on then "\001"
        when "\001" then "\001"
        when :off then "\000"
        when "\000" then "\000"
        else raise SSDP::Error, "Can't switch IP_MULTICAST_LOOP to '#{on_off}'"
        end

        set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, hex_value)
      end
    end
  end
end
