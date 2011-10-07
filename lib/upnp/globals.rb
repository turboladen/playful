ENV["RUBY_UPNP_ENV"] = "production"

module UPnP
  module Globals

    # Default broadcast address
    BROADCAST = '239.255.255.250'

    # Default multicast port
    MULTICAST_PORT = 1900

    # Default TTL
    TTL = 4
  end
end
