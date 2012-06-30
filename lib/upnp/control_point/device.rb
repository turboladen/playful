require_relative 'base'


module UPnP
  class ControlPoint
    class Device < Base

      attr_reader :raw_hash
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

      def initialize(device_as_hash)
        @raw_hash = device_as_hash

        @cache_control = device_as_hash[:cache_control]
        @location = device_as_hash[:location]
        @server = device_as_hash[:server]
        @st = device_as_hash[:st]
        @ext = device_as_hash[:ext]
        @usn = device_as_hash[:usn]

        @description = get_description(@location)
        @devices = []
        @services = []

        extract_description
      end

      def extract_description
        device = @description[:root][:device]

        @friendly_name = device[:friendlyName] || ''
        @manufacturer = device[:manufacturer] || ''
        @manufacturer_url = device[:manufacturerURL] || ''
        @model_description = device[:modelDescription] || ''
        @model_name = device[:modelName] || ''
        @model_number = device[:modelNumber] || ''
        @model_url = device[:modelURL] || ''
        @presentation_url = device[:presentationURL] || ''
        @serial_number = device[:serialNumber] || ''
        @url_base = @description[:root][:URLBase]

        extract_services(device[:serviceList]) || []
      end

=begin
  	  def extract_devices
  	  	# :device is many devices
  	  	if @description[:root][:device].is_a? Array
  	  	# :device is one device
  	  	else
  	  	  Device.new(@description[:root][:device])
  	  	end
  	  end
=end

      def extract_services(service_list)
        service_list.each_value do |service|
          if service.is_a? Array
            service.each do |s|
              #@services << extract_service(device, s)
              @services << Service.new(@url_base, s)
            end
          else
            #@services << extract_service(device, service)
            @services << Service.new(@url_base, service[:SCPDURL])
          end
        end
      end
    end
  end
end
