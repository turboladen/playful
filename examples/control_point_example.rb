require 'upnp/control_point'

class MyClient < UPnP::ControlPoint 
  def start
    find_devices(:root, 5)
    find_services
    listen
  end
end

MyClient.start
