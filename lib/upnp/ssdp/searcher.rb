require_relative 'connection'

class SSDP::Searcher < SSDP::Connection
  def initialize(search, ttl)
    super ttl
    @search = search
  end

  def post_init
    if (send_datagram @search, BROADCAST, MULTICAST_PORT) > 0
      puts("Sent datagram search #1:", @search)
    end
  end

  def receive_data(data)
    if data =~ /(^HTTP|ST:)/i
      puts "<#{self.class}> #{data}"
      responses << data
    end
  end
end
