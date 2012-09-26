require 'pp'
require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/ssdp')
require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/control_point/device')

module Upnp
  class Ssdp < Thor
    #---------------------------------------------------------------------------
    # search
    #---------------------------------------------------------------------------
    desc "search TARGET", "Searches for devices of type TARGET"
    method_option :response_wait_time, default: 5
    method_option :ttl, default: 4
    method_option :do_broadcast_search, type: :boolean
    method_option :log, type: :boolean
    def search(target="upnp:rootdevice")
      UPnP::SSDP.log = options[:log]
      time_before = Time.now
      results = UPnP::SSDP.search(target, options.dup)
      time_after = Time.now

      puts <<-RESULTS
size: #{results.size}
locations: #{results.map { |r| r[:location] }}
unique size: #{results.uniq.size}
unique locations: #{results.uniq.map { |r| r[:location] }}
search duration: #{time_after - time_before}
      RESULTS

      results
    end

    #---------------------------------------------------------------------------
    # search_and_parse
    #---------------------------------------------------------------------------
    desc "search_and_parse TARGET", "Searches for devices, fetches, and parses their DDFs"
    method_option :response_wait_time, default: 3
    method_option :ttl, default: 4
    method_option :do_broadcast_search, type: :boolean
    method_option :log, type: :boolean
    def search_and_parse(target="upnp:rootdevice")
      responses = invoke :search, target
      return if responses.empty?

      devices = []
      successful_devices = 0
      failed_devices = 0
      responses.uniq!

      EM.run do
        responses.each_with_index do |response, i|
          device_creator = UPnP::ControlPoint::Device.new(ssdp_notification: response)

          device_creator.errback do
            puts "<#{self.class}> Failed creating device."
            failed_devices += 1
          end

          device_creator.callback do |built_device|
            devices << built_device
            successful_devices += 1
          end

          device_creator.fetch
        end

        tickloop = EM.tick_loop do
          if (successful_devices + failed_devices) == responses.size
            :stop
          end
        end

        EM.add_periodic_timer(1) do
          puts "successful devices: #{successful_devices}/#{responses.size}"
          puts "failed devices: #{failed_devices}/#{responses.size}"
          puts "Connections: #{EM.connection_count}"
        end

        tickloop.on_stop { EM.stop }
      end

      puts "No devices found" && exit if devices.empty?

      first_device = devices.first

      puts "First device's devices count: #{first_device.devices.size}"
      puts "First device's services count: #{first_device.services.size}"

      if first_device.has_services?
        pp first_device.services
        puts "First Service's ACTIONS"
        pp first_device.services.first.actions
        pp first_device.services.first.methods
        pp first_device.services.first.singleton_methods
        #puts "Services state table"
        #pp devices.first.services.first.service_state_table
        puts "id: #{devices.first.services.first.GetSystemUpdateID}"
      end

      pp first_device
      if first_device.has_devices?
        pp first_device.devices
        pp first_device.devices.first.services
        puts "First Child Device's Service"
        pp first_device.devices.first.services.first
        puts "First Child Device's Service's ACTIONS"
        pp first_device.devices.first.services.first.actions
        pp first_device.devices.first.services.first.singleton_methods
        #puts "Services state table"
        #pp devices.first.services.first.service_state_table
        modules = first_device.devices.first.services.first.GetModules
        pp modules

      end

      #if devices.last.has_services?
      #  puts "Last Service's ACTIONS"
      #  pp devices.first.services.last.actions
      #  puts "Services state table"
      #  pp devices.first.services.last.service_state_table
      #  puts "protocol info: #{devices.first.services.last.GetProtocolInfo}"
      #end
    end
  end
end
