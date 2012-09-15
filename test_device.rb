require './lib/upnp/device'

d = UPnP::Device.new('0.0.0.0', 49159)
d.start
