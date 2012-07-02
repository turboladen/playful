require 'upnp/control_point'


device = UPnP::SSDP.search(:root).first
p device

cp = UPnP::ControlPoint.new(device[:usn])

p cp
cp.start
