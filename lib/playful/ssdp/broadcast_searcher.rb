require_relative '../../core_ext/socket_patch'
require_relative '../logger'
require_relative 'network_constants'
require 'ipaddr'
require 'socket'
require 'eventmachine'


# TODO: DRY this up!!  (it's mostly the same as Playful::SSDP::MulticastConnection)
module Playful
  class SSDP
    class BroadcastSearcher < EventMachine::Connection
      include LogSwitch::Mixin
      include EventMachine::Deferrable
      include Playful::SSDP::NetworkConstants

      # @return [Array] The list of responses from the current discovery request.
      attr_reader :discovery_responses

      attr_reader :available_responses
      attr_reader :byebye_responses

      def initialize(search_target, response_wait_time, ttl=TTL)
        @ttl = ttl
        @discovery_responses = []
        @alive_notifications = []
        @byebye_notifications = []

        setup_broadcast_socket

        @search = m_search(search_target, response_wait_time)
      end

      def post_init
        if send_datagram(@search, BROADCAST_IP, MULTICAST_PORT) > 0
          log "Sent broadcast datagram search:\n#{@search}"
        end
      end

      def m_search(search_target, response_wait_time)
        <<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: #{MULTICAST_IP}:#{MULTICAST_PORT}\r
MAN: "ssdp:discover"\r
MX: #{response_wait_time}\r
ST: #{search_target}\r
\r
        MSEARCH
      end

      # Gets the IP and port from the peer that just sent data.
      #
      # @return [Array<String,Fixnum>] The IP and port.
      def peer_info
        peer_bytes = get_peername[2, 6].unpack('nC4')
        port = peer_bytes.first.to_i
        ip = peer_bytes[1, 4].join('.')

        [ip, port]
      end

      def receive_data(response)
        ip, port = peer_info
        log "Response from #{ip}:#{port}:\n#{response}\n"
        parsed_response = parse(response)

        if parsed_response.has_key? :nts
          if parsed_response[:nts] == 'ssdp:alive'
            @alive_notifications << parsed_response
          elsif parsed_response[:nts] == 'ssdp:bye-bye'
            @byebye_notifications << parsed_response
          else
            raise "Unknown NTS value: #{parsed_response[:nts]}"
          end
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
          log 'Received response as a single-line String.  Discarding.'
          log "Bad response looked like:\n#{data}"
          return new_data
        end

        data.each_line do |line|
          line =~ /(\S*):(.*)/

          unless $1.nil?
            key = $1
            value = $2
            key = key.gsub('-', '_').downcase.to_sym
            new_data[key] = value.strip
          end
        end

        new_data
      end

      # Sets Socket options to allow for brodcasting.
      def setup_broadcast_socket
        set_sock_opt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      end
    end
  end
end
