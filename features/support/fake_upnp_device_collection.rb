require 'singleton'
require 'socket'
require 'ipaddr'

require_relative '../../lib/playful/ssdp/network_constants'

class FakeUPnPDeviceCollection
  include Singleton
  include UPnP::SSDP::NetworkConstants

  attr_accessor :respond_with

  def initialize
    @response = ''
    @ssdp_listen_thread = nil
    @serve_description = false
    @local_ip, @local_port = local_ip_and_port
  end

  def expect_discovery(type)
    case type
    when :m_search

    end

  end

  def stop_ssdp_listening
    puts "<#{self.class}> Stopping..."
    @ssdp_listen_thread.kill if @ssdp_listen_thread && @ssdp_listen_thread.alive?
    puts "<#{self.class}> Stopped."
  end

  # @return [Thread] The thread that's doing the listening.
  def start_ssdp_listening
    multicast_socket = setup_multicast_socket
    multicast_socket.bind(MULTICAST_IP, MULTICAST_PORT)

    ttl = [4].pack 'i'
    unicast_socket = UDPSocket.open
    unicast_socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, ttl)

    @ssdp_listen_thread = Thread.new do
      loop do
        text, sender = multicast_socket.recvfrom(1024)
        #puts "<#{self.class}> received text:\n#{text} from #{sender}"

        #if text =~ /ST: upnp:rootdevice/
        #if text =~ /#{@response}/m
        if text =~ /M-SEARCH.*#{@local_ip}/m
          puts "<#{self.class}> received text:\n#{text} from #{sender}"
          return_port, return_ip = sender[1], sender[2]

          puts "<#{self.class}> sending response\n#{@response}\n back to: #{return_ip}:#{return_port}"
          unicast_socket.send(@response, 0, return_ip, return_port)
          #multicast_socket.close
        end
      end
    end
  end

  def start_serving_description
=begin
    tcp_server = TCPServer.new('0.0.0.0', 4567)
    @serve_description = true

    while @serve_description
      @description_serve_thread = Thread.start(tcp_server.accept) do |s|
        print(s, " is accepted\n")
        s.write(Time.now)
        print(s, " is gone\n")
        s.close
      end
    end
=end
    require 'webrick'
    @description_server = WEBrick::HTTPServer.new(Port: 4567)
    trap('INT') { @description_server.shutdown }
    @description_server.mount_proc '/' do |req, res|
      res.body = "<start>\n</start>"
    end
    @description_server.start
  end

  def stop_serving_description
=begin
    @serve_description = false

    if @description_serve_thread && @description_serve_thread.alive?
      @description_serve_thread.join
    end
=end
    @description_server.stop
  end

  def setup_multicast_socket
    membership = IPAddr.new(MULTICAST_IP).hton + IPAddr.new('0.0.0.0').hton
    ttl = [4].pack 'i'

    socket = UDPSocket.new
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\000")
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, ttl)
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_TTL, ttl)

    socket
  end
end
