require 'singleton'
require 'socket'
require 'ipaddr'

require_relative '../../lib/upnp/globals'

class FakeUPnPDeviceCollection
  include Singleton
  include UPnP::Globals

  attr_accessor :response

  def initialize
    @response = "bobo"
    @run_thread = nil
  end

  def stop
    puts "<#{self.class}> Stopping..."
    @run_thread.kill
    puts "<#{self.class}> Stopped..."
  end

  def start
    multicast_socket = setup_multicast_socket
    multicast_socket.bind(BROADCAST, MULTICAST_PORT)

    ttl = [4].pack 'i'
    unicast_socket = UDPSocket.open
    unicast_socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, ttl)

    @run_thread = Thread.new do
      loop do
        text, sender = multicast_socket.recvfrom(1024)
        puts "<#{self.class}> received text:\n#{text} from #{sender}"

        if text =~ /ST: upnp:rootdevice/
          return_port, return_ip = sender[1], sender[2]

          puts "<#{self.class}> sending response\n#{@response}\n back to: #{return_ip}:#{return_port}"
          unicast_socket.send(@response, 0, return_ip, return_port)
          #multicast_socket.close
        end
      end
    end
  end

  def setup_multicast_socket
    membership = IPAddr.new(BROADCAST).hton + IPAddr.new('0.0.0.0').hton
    ttl = [4].pack 'i'

    socket = UDPSocket.new
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
    #socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\001")
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, ttl)
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_TTL, ttl)

    socket
  end
end
