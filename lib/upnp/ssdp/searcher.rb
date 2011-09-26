require_relative 'connection'

class SSDP::Searcher < SSDP::Connection
  def initialize(search_target, response_wait_time, ttl)
    super ttl
    @search = m_search(search_target, response_wait_time)
  end

  def post_init
    if send_datagram(@search, BROADCAST, MULTICAST_PORT) > 0
      puts("Sent datagram search #1:\n", @search)
    end
  end

  # Builds the M-SEARCH request string.
  #
  # @param [String] search_target
  # @param [Fixnum] response_wait_time
  def m_search(search_target, response_wait_time)
    <<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: #{BROADCAST}:#{MULTICAST_PORT}\r
MAN: "ssdp:discover"\r
MX: #{response_wait_time}\r
ST: #{search_target}\r
\r
    MSEARCH
  end
end
