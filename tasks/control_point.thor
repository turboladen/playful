require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/control_point')
require 'ap'

module Upnp
  class ControlPoint < Thor
    desc "test TARGET", "Make a control point"
    def test(target="upnp:rootdevice")
      cp = UPnP::ControlPoint.new(target)

      cp.start
    end
  end
end
