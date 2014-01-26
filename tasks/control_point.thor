require 'bundler/setup'
require File.expand_path(File.dirname(__FILE__)+ '/../lib/playful/control_point')
require 'rack'
require 'em-websocket'

Playful::ControlPoint.raise_on_remote_error = false

module Playful
  class ControlPoint < Thor
    desc "test TARGET", "Make a control point"
    def test(target="upnp:rootdevice")
      cp = Playful::ControlPoint.new(target)

      cp.start do |new_device_channel, old_device_channel|
        EM.defer do
          EM::WebSocket.start(host: '0.0.0.0', port: 8080, debug: true) do |ws|
            ws.onopen do
              new_device_channel.subscribe do |device|
                puts "New device in channel: #{device.friendly_name}"

                ws.send "[#{Time.now}] #{device.friendly_name}: #{device.device_type}"

                device.service_list.each do |service|
                  ws.send "-- #{service.service_type}"

                  service.action_list.each do |action|
                    ws.send "---- #{action[:name]}"
                    ws.send "---- #{action[:argumentList]}"
                  end
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
end

