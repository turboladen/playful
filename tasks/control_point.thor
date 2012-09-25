require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/control_point')
require 'rack'
require 'sinatra'
require 'sinatra/async'


module Upnp
  class ControlPoint < Thor
    desc "test TARGET", "Make a control point"
    def test(target="upnp:rootdevice")
      UPnP::ControlPoint.config { |c| c.raise_on_remote_errors = false }

      cp = UPnP::ControlPoint.new(target)

      cp.start do |new_device_queue, old_device_queue|
        control_point_web = Class.new(Sinatra::Base) do
          register Sinatra::Async

          configure do
            @@devices = []
          end

          before do
            new_device_queue.pop { |d| @@devices << d }

            old_device_queue.pop do |device|
              @devices.reject! do |d|
                d.usn == device[:usn]
              end
            end
          end

          get '/' do
            @devices = @@devices

            code = %Q{
<html>
<head>
</head>
<body
<h1><%= Time.now %></h1>
<% @devices.each do |device| %>
  <table border="1">
    <thead>
      <caption>
        <strong><%= device.friendly_name %></strong>
      </caption>
    </thead>
    <tbody>
      <tr>
        <td>Device type:</td>
        <td><%= device.device_type %></td>
      </tr>
      <tr>
        <td>Service info:</td>
        <td>
          <% device.services.each do |service| %>
            <table border="2">
              <tr>
                <td>Service type:</td>
                <td><%= service.service_type %>
              </tr>
              <tr>
                <td>Service actions:</td>
                <td>
                  <% service.actions.each do |action| %>
                    <table border="3">
                      <tr>
                        <td>Name:</td>
                        <td><%= action[:name] %></td>
                      </tr>
                      <tr>
                        <td>Arguments:</td>
                        <td><%= action[:argumentList] %></td>
                      </tr>
                    </table>
                  <% end %>
                </td>
              </tr>
            </table>
          <% end %>
        </td>
      </tr>
    </tbody>
  </table>
<% end %>
</body>
</html>
}

            erb code
          end
        end

        control_point_web.run! port: 3000
      end
    end
  end
end

