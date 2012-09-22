require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/ssdp')
require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/control_point/device')
require 'ap'

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
      results = UPnP::SSDP.search(target, options.dup)

      puts <<-RESULTS
size: #{results.size}
locations: #{results.map { |r| r[:location] }}
unique size: #{results.uniq.size}
unique locations: #{results.uniq.map { |r| r[:location] }}
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
      devices = []
      responses.uniq!

      EM.run do
        # The evented way...
        EM::Iterator.new(responses, responses.size).map(
          proc do |response, iter|
            device_creator = UPnP::ControlPoint::Device.new(m_search_response: response)

            device_creator.callback do |built_device|
              puts "Local device creator callback called"
              iter.return built_device
            end

            device_creator.fetch
          end,
          proc do |found_devices|
            devices = found_devices
            EM.stop
        end
        )
=begin
        # The non-evented way...
        until responses.empty? do
          device_creator = UPnP::ControlPoint::Device.new(m_search_response: responses.pop)

          device_creator.callback do |built_device|
            devices << built_device
            EM.stop if responses.empty?
          end

          device_creator.fetch
        end
=end
      end

      puts "No devices found" && exit if devices.empty?

      first_device = devices.first

      puts "First device's devices count: #{first_device.devices.size}"
      puts "First device's services count: #{first_device.services.size}"

      if first_device.has_services?
        ap first_device.services
        puts "First Service's ACTIONS"
        ap first_device.services.first.actions
        ap first_device.services.first.methods
        ap first_device.services.first.singleton_methods
        #puts "Services state table"
        #ap devices.first.services.first.service_state_table
        puts "id: #{devices.first.services.first.GetSystemUpdateID}"
      end

      ap first_device
      if first_device.has_devices?
        ap first_device.devices
        ap first_device.devices.first.services
        puts "First Child Device's Service's ACTIONS"
        ap first_device.devices.first.services.first.actions
        ap first_device.devices.first.services.first.singleton_methods
        #puts "Services state table"
        #ap devices.first.services.first.service_state_table
        modules = first_device.devices.first.services.first.GetModules
        ap modules

      end

      #if devices.last.has_services?
      #  puts "Last Service's ACTIONS"
      #  ap devices.first.services.last.actions
      #  puts "Services state table"
      #  ap devices.first.services.last.service_state_table
      #  puts "protocol info: #{devices.first.services.last.GetProtocolInfo}"
      #end
    end
  end
end
