require_relative 'connection'

class SSDP::Searcher < SSDP::Connection
  def initialize(search, ttl)
    super ttl
    @search = search
  end

  def post_init
    setup_multicast_socket
    send_datagram @search, BROADCAST, MULTICAST_PORT
    puts "Send search: #{@search}"
  end

  def receive_data(data)
    p data if data =~ /^HTTP/
    puts "meow", data if data =~ /ST:/i
  end
end
