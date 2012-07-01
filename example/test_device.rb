require './lib/upnp/device'

d = UPnP::Device.new(1, 2)

d.start
