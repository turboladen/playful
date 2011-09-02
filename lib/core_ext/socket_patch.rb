require 'socket'

# Workaround for missing constants on Windows
module Socket::Constants
  IP_ADD_MEMBERSHIP = 12 unless defined? IP_ADD_MEMBERSHIP
  IP_MULTICAST_LOOP = 11 unless defined? IP_MULTICAST_LOOP
  IP_MULTICAST_TTL  = 10 unless defined? IP_MULTICAST_TTL
  IP_TTL            =  4 unless defined? IP_TTL
end

class Socket
  IP_ADD_MEMBERSHIP = 12 unless defined? IP_ADD_MEMBERSHIP
  IP_MULTICAST_LOOP = 11 unless defined? IP_MULTICAST_LOOP
  IP_MULTICAST_TTL  = 10 unless defined? IP_MULTICAST_TTL
  IP_TTL            =  4 unless defined? IP_TTL
end
