require_relative 'ssdp'
require 'open-uri'
require 'nori'

begin
  require 'nokogiri'
rescue LoadError
  # Fail quietly
end

# Allows for controlling a UPnP device as defined in the UPnP spec for control
# points.
#
# It uses +Nori+ for parsing the description XML files, which will use +Nokogiri+
# if you have it installed.
module UPnP
  class ControlPoint
    attr_reader :devices
    attr_reader :services

    def initialize(ip='0.0.0.0', port=0)
      @ip = ip
      @port = port
      @devices = []
      @services = []
      Nori.parser = :nokogiri if defined? ::Nokogiri
    end

    def find_devices
      @devices = SSDP.search("ssdp:all")
      @devices = SSDP.search "upnp:rootdevice" if @devices.empty?

      @devices.each do |device|
        device[:description] = get_description(device[:location])
      end
    end

    def get_description(location)
      Nori.parse(open(location).read)
    end

    def find_services
      return [] if @devices.empty?

      @devices.each do |device|
        device[:description]["root"]["device"]["serviceList"]["service"].each do |service|
          scpd_url = build_scpd_url(device[:description]["root"]["URLBase"], service["SCPDURL"])
          puts scpd_url
          service[:description] = get_description(scpd_url)
          p service[:description]
          @services << service
        end
      end
    end

    def build_scpd_url(url_base, scpdurl)
      if url_base.end_with?('/') && scpdurl.start_with?('/')
        scpdurl.sub!('/', '')
      end

      url_base + scpdurl
    end
  end
end
