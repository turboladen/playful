require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/control_point')
require 'rack'


module Upnp
  class ControlPoint < Thor
    desc "test TARGET", "Make a control point"
    def test(target="upnp:rootdevice")
      cp = UPnP::ControlPoint.new(target)

      cp.start do |device_queue|
        EM::WebSocket.start(host: '0.0.0.0', port: 8080, debug: true) do |ws|
          ws.onopen do
            device_queue.pop do |device|
              ws.send "[#{Time.now}] #{device.friendly_name}: #{device.device_type}"

              device.services.each do |service|
                ws.send "----- #{service.service_type}"
              end
            end
          end
        end

        Rack::Handler::Thin.run(Rack::Builder.new {
          run Rack::File.new(File.expand_path(File.dirname(__FILE__) + "/control_point.html"))
        }, Port: 3000)
      end
    end
  end
end

