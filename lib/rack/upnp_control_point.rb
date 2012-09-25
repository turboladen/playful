require 'rack'

module Rack
  class UPnPControlPoint
    def initialize(app, search_type)
      @app = app
      @devices = []
      EM.next_tick { start_control_point(search_type) }
    end

    def start_control_point(search_type)
      @cp = UPnP::ControlPoint.new search_type

      @cp.start do |new_device_queue, old_device_queue|
        new_device_queue.pop { |new_device| @devices << new_device }

        old_device_queue.pop do |old_device|
          @devices.reject! { |d| d.usn == old_device[:usn] }
        end
      end
    end

    def call(env)
      env['upnp.devices'] = @devices
      @app.call(env)
    end
  end
end
