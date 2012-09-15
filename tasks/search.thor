require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/ssdp')
require File.expand_path(File.dirname(__FILE__)+ '/../lib/upnp/control_point/device')
require 'pp'

module Upnp
  class Ssdp < Thor
    #---------------------------------------------------------------------------
    # search
    #---------------------------------------------------------------------------
    desc "search TARGET", "Searches for devices of type TARGET"
    method_option :response_wait_time, default: 3
    method_option :ttl, default: 4
    method_option :search_count, default: 2
    method_option :broadcast_search, default: false
    method_option :log, type: :boolean
    def search(target="upnp:rootdevice")
      UPnP::SSDP.log = options[:log]

      puts "target: #{target}"
      puts "target class: #{target.class}"
      results = UPnP::SSDP.search(target,
        options[:response_wait_time],
        options[:ttl],
        options[:search_count],
        options[:broadcast_search])

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
    desc "search_and_fetch TARGET", "Searches for devices, fetches, and parses their DDFs"
    method_option :response_wait_time, default: 3
    method_option :ttl, default: 4
    method_option :search_count, default: 2
    method_option :broadcast_search, default: false
    method_option :log, type: :boolean
    def search_and_parse(target="upnp:rootdevice")
      responses = invoke :search, target
      devices = responses.uniq.map { |r| UPnP::ControlPoint::Device.new(r) }
      pp devices
    end
  end
end
