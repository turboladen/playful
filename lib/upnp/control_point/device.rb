require_relative 'base'
require_relative 'service'
require 'uri'


module UPnP
  class ControlPoint
    class Device < Base

      attr_reader :m_search_response
      attr_reader :description
      attr_reader :cache_control
      attr_reader :location
      attr_reader :server
      attr_reader :st
      attr_reader :ext
      attr_reader :usn

      # @return [String] Short device description for the end user.
      attr_reader :friendly_name

      # @return [String] Manufacturer's name.
      attr_reader :manufacturer

      # @return [String] Manufacturer's web site.
      attr_reader :manufacturer_url

      # @return [String] Long model description for the end user, from the description file.
      attr_reader :model_description

      # @return [String] Model name of this device from the description file.
      attr_reader :model_name

      # @return [String] Model number of this device from the description file.
      attr_reader :model_number

      # @return [String] Web site for model of this device.
      attr_reader :model_url

      # Unique Device Name (UDN), a universally unique identifier for the device
      # whether root or embedded.
      #attr_reader :name

      # @return [String] URL for device control via a browser.
      attr_reader :presentation_url

      # @return [String] The serial number from the description file.
      attr_reader :serial_number

      # All services provided by this device and its sub-devices.
      attr_reader :service_list

      # Devices embedded directly into this device.
      attr_reader :devices

      # Services provided directly by this device.
      attr_reader :services

      # @return [String] The type of UPnP device (URN) from the description file.
      attr_reader :device_type

      # @return [String] The UPC of the device from the description file.
      attr_reader :upc

      # @return [String] URLBase from the device's description file.
      attr_reader :url_base

      # @return [Hash] :major and :minor revisions of the UPnP spec this device adheres to.
      attr_reader :spec_version

      # @return [Array<Hash>] An Array where each element is a Hash that describes an icon.
      attr_reader :icon_list

      # @return [String] The xmlns attribute of the device from the description file.
      attr_reader :xmlns

      # @return [String] The UDN for the device, from the description file.
      attr_reader :udn

      # @param [Hash] device_info
      # @option device_info [Hash] m_search_response
      # @option device_info [Hash] device_description
      # @option device_info [Hash] parent_base_url
      def initialize(device_info)
        super()

        @devices = []
        @services = []

        if device_info.has_key? :m_search_response
          @m_search_response = device_info[:m_search_response]

          @cache_control = @m_search_response[:cache_control]
          @location = m_search_response[:location]
          @server = m_search_response[:server]
          @st = m_search_response[:st]
          @ext = m_search_response[:ext]
          @usn = m_search_response[:usn]

          @description = get_description(@location)
        elsif device_info.has_key? :device_description
          @description = device_info[:device_description]
        end

        @url_base = if @description[:root] && @description[:root][:URLBase]
          @description[:root][:URLBase]
        elsif device_info[:parent_base_url]
          device_info[:parent_base_url]
        else
          tmp_uri = URI(@location)
          "#{tmp_uri.scheme}://#{tmp_uri.host}:#{tmp_uri.port}/"
        end

        if device_info[:m_search_response]
          extract_description(@description[:root][:device])
        elsif device_info.has_key? :device_description
          extract_description(@description)
        end

        @devices = extract_devices
      end

      def has_devices?
        !@devices.empty?
      end

      def has_services?
        !@services.empty?
      end

      def extract_description(ddf)

        @friendly_name = ddf[:friendlyName] || ''
        @manufacturer = ddf[:manufacturer] || ''
        @manufacturer_url = ddf[:manufacturerURL] || ''
        @model_description = ddf[:modelDescription] || ''
        @model_name = ddf[:modelName] || ''
        @model_number = ddf[:modelNumber] || ''
        @model_url = ddf[:modelURL] || ''
        @presentation_url = ddf[:presentationURL] || ''
        @serial_number = ddf[:serialNumber] || ''

        extract_services(ddf[:serviceList]) || []
      end

      def extract_devices
        device_list = if @description.has_key? :root
          @description[:root][:device][:deviceList][:device]
        elsif @description.has_key? :deviceList
          @description[:deviceList][:device]
        end

        return if device_list.nil?

        if device_list.is_a? Hash
          [Device.new(device_description: device_list, parent_base_url: @url_base)]
        elsif device_list.is_a? Array
          device_list.map do |device|
            Device.new(device_description: device, parent_base_url: @url_base)
          end
        end
      end

      def extract_services(service_list)
        return if service_list.nil?

        service_list.each_value do |service|
          if service.is_a? Array
            service.each do |s|
              @services << Service.new(@url_base, s)
            end
          else
            @services << Service.new(@url_base, service)
          end
        end
      end
    end
  end
end
