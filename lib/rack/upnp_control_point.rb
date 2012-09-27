require 'rack'
require_relative '../upnp/control_point'

module Rack

  # Middleware that allows your Rack app to keep tabs on devices that the
  # UPnP::ControlPoint has found.  UPnP devices that match the +search_type+
  # are discovered and added to the list, then removed as those devices send out
  # ssdp:byebye notifications.  All of this depends on EventMachine::Queues,
  # and thus requires that an EventMachine reactor is running.  If you don't
  # have one running, the UPnP::ControlPoint will start one for you.
  #
  # @example Control all root devices
  #
  #   Thin::Server.start('0.0.0.0', 3000) do
  #     use Rack::UPnPControlPoint, search_type: :root
  #
  #     map "/devices" do
  #       run lambda { |env|
  #         devices = env['upnp.devices']
  #         friendly_names = devices.map(&:friendly_name).join("\n")
  #         [200, {'Content-Type' => 'text/plain'}, [friendly_names]]
  #       }
  #     end
  #   end
  #
  class UPnPControlPoint

    # @param [Rack::Builder] app Your Rack application.
    # @param [Symbol,String] search_type The device(s) you want to search for
    #   and control.  See docs for UPnP::SSDP::Searcher.
    # @param [Hash] options Options to pass to the UPnP::SSDP::Searcher.
    def initialize(app, options={})
      @app = app
      @devices = []
      options[:search_type] ||= :root
      EM.next_tick { start_control_point(options[:search_type], options) }
    end

    # Creates and starts the UPnP::ControlPoint, then manages the list of devices
    # using the EventMachine::Queue objects yielded in.
    #
    # @param [Symbol,String] search_type The device(s) you want to search for
    #   and control.  See docs for UPnP::SSDP::Searcher.
    # @param [Hash] options Options to pass to the UPnP::SSDP::Searcher.
    def start_control_point(search_type, options)
      @cp = ::UPnP::ControlPoint.new(search_type, options)

      @cp.start do |new_device_channel, old_device_channel|
        new_device_channel.subscribe do |notification|
          @devices << notification
        end

        old_device_channel.subscribe do |old_device|
          @devices.reject! { |d| d.usn == old_device[:usn] }
        end
      end

    end

    # Adds the whole list of devices to +env['upnp.devices']+ so that that list
    # can be accessed from within your app.
    #
    # @param [Hash] env The Rack environment.
    def call(env)
      puts "Rack::UPnPControlPoint: devices size: #{@devices.size}"
      env['upnp.devices'] = @devices
      @app.call(env)
    end
  end
end
