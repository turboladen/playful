require 'open-uri'
require 'nori'
require_relative 'ssdp'

begin
  require 'nokogiri'
rescue LoadError
  # Fail quietly
end

module UPnP

  # Allows for controlling a UPnP device as defined in the UPnP spec for control
  # points.
  #
  # It uses +Nori+ for parsing the description XML files, which will use +Nokogiri+
  # if you have it installed.
  class ControlPoint
    attr_reader :devices
    attr_reader :services

    def initialize(ip='0.0.0.0', port=0)
      @ip = ip
      @port = port
      @devices = []
      @services = []
      Nori.parser = :nokogiri if defined? ::Nokogiri
      Nori.configure do |config|
        config.convert_tags_to { |tag| tag.to_sym }
      end
    end

    def start
      response_wait_time = 5

      EM.run do
        searcher = EM.open_datagram_socket(@ip, 0, UPnP::SSDP::Searcher,
          "ssdp:all", response_wait_time, 4)

        searcher.callback do
          extract_devices_and_services(searcher.responses)
        end

        EM.add_timer(response_wait_time) do
          searcher.set_deferred_status(:succeeded)
          searcher.close_connection
        end

        EM.add_periodic_timer(5) do
          puts "Device count: #{@devices.size}"
          puts "Service count: #{@services.size}"
        end
      end
    end

    def extract_devices_and_services(new_devices)
      @devices = new_devices.map do |device|
        { description: get_description(device[:location]) }
      end

      find_services
    end

    # @param [String] search_type
    # @param [Fixnum] max_wait_time The MX value to use for searching.
    # @param [Fixnum] ttl
    # @return [Hash]
=begin
    def find_devices(search_type, max_wait_time, ttl=4)
      @devices = UPnP::SSDP.search(search_type, max_wait_time, ttl)

      @devices.each do |device|
        device[:description] = get_description(device[:location])
      end
    end
=end

    def find_services
      if @devices.empty?
        return
      end

      @devices.each do |device|
        next if device[:description][:root][:device][:serviceList].nil?

        device[:description][:root][:device][:serviceList].each_value do |service|
          scpd_url = build_scpd_url(device[:description][:root][:URLBase], service[:SCPDURL])
          service[:description] = get_description(scpd_url)
          @services << service
        end
      end
    end

    private

    def get_description(location)
      Nori.parse(open(location).read)
    end

    def build_scpd_url(url_base, scpdurl)
      if url_base.end_with?('/') && scpdurl.start_with?('/')
        scpdurl.sub!('/', '')
      end

      url_base + scpdurl
    end
  end
end
