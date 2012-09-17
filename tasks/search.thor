require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/ssdp')
require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/control_point/device')
require 'ap'

module Upnp
  class Ssdp < Thor
    #---------------------------------------------------------------------------
    # search
    #---------------------------------------------------------------------------
    desc "search TARGET", "Searches for devices of type TARGET"
    method_option :response_wait_time, default: 3
    method_option :ttl, default: 4
    method_option :search_count, default: 2
    method_option :do_broadcast_search, type: :boolean
    method_option :log, type: :boolean
    def search(target="upnp:rootdevice")
      UPnP::SSDP.log = options[:log]
      results = UPnP::SSDP.search(target, options)
      ap results

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
    method_option :search_count, default: 2
    method_option :do_broadcast_search, type: :boolean
    method_option :log, type: :boolean
    def search_and_parse(target="upnp:rootdevice")
      responses = invoke :search, target
      devices = responses.uniq.map { |r| UPnP::ControlPoint::Device.new(m_search_response: r) }
      
      #puts "SERVICES"
      #ap devices.first.services
      puts "No devices found" && exit if devices.empty?

      #ap devices.first.description
      puts "child devices: #{devices.first.devices.size}"

      if devices.first.has_services?
        puts "First Service's ACTIONS"
        ap devices.first.services.first.actions
        #puts "Services state table"
        #ap devices.first.services.first.service_state_table
        puts "id: #{devices.first.services.first.GetSystemUpdateID}"
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
