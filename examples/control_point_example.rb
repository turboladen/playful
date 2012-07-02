require 'upnp/control_point'


device = UPnP::SSDP.search(:root).first

cp = UPnP::ControlPoint.new(device[:usn])
cp.start
