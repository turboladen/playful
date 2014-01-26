require_relative '../logger'
require_relative 'multicast_connection'

module Playful

  # A subclass of an EventMachine::Connection, this handles doing M-SEARCHes.
  #
  # Search types:
  #   ssdp:all
  #   upnp:rootdevice
  #   uuid:[device-uuid]
  #   urn:schemas-upnp-org:device:[deviceType-version]
  #   urn:schemas-upnp-org:service:[serviceType-version]
  #   urn:[custom-schema]:device:[deviceType-version]
  #   urn:[custom-schema]:service:[serviceType-version]
  class SSDP::Searcher < SSDP::MulticastConnection
    include LogSwitch::Mixin

    DEFAULT_RESPONSE_WAIT_TIME = 5
    DEFAULT_M_SEARCH_COUNT = 2

    # @return [EventMachine::Channel] Provides subscribers with responses from
    #   their search request.
    attr_reader :discovery_responses

    # @param [String] search_target
    # @param [Hash] options
    # @option options [Fixnum] response_wait_time
    # @option options [Fixnum] ttl
    # @option options [Fixnum] m_search_count The number of times to send the
    #   M-SEARCH.  UPnP 1.0 suggests to send the request more than once.
    def initialize(search_target, options={})
      options[:ttl] ||= TTL
      options[:response_wait_time] ||= DEFAULT_RESPONSE_WAIT_TIME
      @m_search_count = options[:m_search_count] ||= DEFAULT_M_SEARCH_COUNT

      @search = m_search(search_target, options[:response_wait_time])

      super options[:ttl]
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
      log "Response from #{ip}:#{port}:\n#{response}\n"
      parsed_response = parse(response)

      return if parsed_response.has_key? :nts
      return if parsed_response[:man] && parsed_response[:man] =~ /ssdp:discover/

      @discovery_responses << parsed_response
    end

    # Sends the M-SEARCH that was built during init.  Logs what was sent if the
    # send was successful.
    def post_init
      @m_search_count.times do
        if send_datagram(@search, MULTICAST_IP, MULTICAST_PORT) > 0
          log "Sent datagram search:\n#{@search}"
        end
      end
    end

    # Builds the M-SEARCH request string.
    #
    # @param [String] search_target
    # @param [Fixnum] response_wait_time
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
  end
end
