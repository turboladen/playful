require_relative 'multicast_connection'

module UPnP

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

    # @param [String] search_target
    # @param [Fixnum] response_wait_time
    # @param [Fixnum] ttl
    def initialize(search_target, response_wait_time, ttl)
      @search = m_search(search_target, response_wait_time)
      super ttl
    end

    # Sends the M-SEARCH that was built during init.  Logs what was sent if the
    # send was successful.
    def post_init
      if send_datagram(@search, MULTICAST_IP, MULTICAST_PORT) > 0
        SSDP.log("Sent datagram search:\n#{@search}")
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
