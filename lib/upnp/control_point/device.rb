require_relative 'base'
require_relative 'service'
require 'uri'
require 'eventmachine'


module UPnP
  class ControlPoint
    class Device < Base
      include EM::Deferrable
      include LogSwitch::Mixin

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

        @device_info = device_info
        @devices = []
        @services = []
      end

      def fetch
        description_getter = EventMachine::DefaultDeferrable.new

        if @device_info.has_key? :m_search_response
          @m_search_response = @device_info[:m_search_response]

          @cache_control = @m_search_response[:cache_control]
          @location = m_search_response[:location]
          @server = m_search_response[:server]
          @st = m_search_response[:st]
          @ext = m_search_response[:ext]
          @usn = m_search_response[:usn]

          if @location
            get_description(@location, description_getter)
          else
            message = "M-SEARCH response is either missing the Location header or has an empty value."
            message << "Response: #{@m_search_response}"
            raise message
          end
        elsif @device_info.has_key? :device_description
          description_getter.set_deferred_status(:succeeded, @device_info[:device_description])
        else
          description_getter.set_deferred_status(:failed)
        end

        description_getter.errback do
          log "<#{self.class}> Failed getting description..."
        end

        description_getter.callback do |description|
          log "<#{self.class}> Description received from #{description_getter.object_id}"
          @description = description

          if @description.nil?
            log "<#{self.class}> Description is empty."
            set_deferred_status(:failed, "Got back an empty description...")
            return
          end

          @url_base = extract_url_base
          log "<#{self.class}> Set url_base to #{@url_base}"

          if @device_info[:m_search_response]
            extract_description(@description[:root][:device])
          elsif @device_info.has_key? :device_description
            extract_description(@description)
          end

          device_extractor = EventMachine::DefaultDeferrable.new
          extract_devices(device_extractor)

          device_extractor.callback do |device|
            if device
              log "<#{self.class}> Device extracted from #{device_extractor.object_id}."
              @devices << device
            else
              log "<#{self.class}> Device extraction done from #{device_extractor.object_id} but none was extracted."
            end

            log "<#{self.class}> Device size is now: #{@devices.size}"
            services_extractor = EventMachine::DefaultDeferrable.new
            services_extractor.callback do |services|
              log "<#{self.class}> Done extracting services."
              @services = services

              log "<#{self.class}> New service count: #{@services.size}."
              set_deferred_status :succeeded, self
            end

            if @description[:serviceList]
              extract_services(@description[:serviceList], services_extractor)
            elsif @description[:root][:device][:serviceList]
              extract_services(@description[:root][:device][:serviceList], services_extractor)
            end
          end
        end
      end

      def extract_url_base
        if @description[:root] && @description[:root][:URLBase]
          @description[:root][:URLBase]
        elsif @device_info[:parent_base_url]
          @device_info[:parent_base_url]
        else
          tmp_uri = URI(@location)
          "#{tmp_uri.scheme}://#{tmp_uri.host}:#{tmp_uri.port}/"
        end
      end


      def has_devices?
        !@devices.empty?
      end

      def has_services?
        !@services.empty?
      end

      def extract_description(ddf)
        log "<#{self.class}> Extracting description..."

        @friendly_name = ddf[:friendlyName] || ''
        @manufacturer = ddf[:manufacturer] || ''
        @manufacturer_url = ddf[:manufacturerURL] || ''
        @model_description = ddf[:modelDescription] || ''
        @model_name = ddf[:modelName] || ''
        @model_number = ddf[:modelNumber] || ''
        @model_url = ddf[:modelURL] || ''
        @presentation_url = ddf[:presentationURL] || ''
        @serial_number = ddf[:serialNumber] || ''

        log "<#{self.class}> Description extracted."
      end

      def extract_devices(device_extractor)
        log "<#{self.class}> Extracting devices..."

        device_list = if @description.has_key? :root
          if @description[:root][:device].has_key? :deviceList
            @description[:root][:device][:deviceList][:device]
          else
            @description[:root][:device]
          end
        elsif @description[:deviceList]
          @description[:deviceList][:device]
        else
          log "<#{self.class}> No devices to extract."
          device_extractor.set_deferred_status(:succeeded)
        end

        return if device_list.nil?

        log "<#{self.class}> device list: #{device_list}"

        if device_list.is_a? Hash
          extract_device(device_list, device_extractor)
        elsif device_list.is_a? Array
          device_list.map do |device|
            extract_device(device, device_extractor)
          end
        end
      end

      def extract_device(device, device_extractor)
        deferred_device = Device.new(device_description: device, parent_base_url: @url_base)

        deferred_device.errback do
          log "<#{self.class}> Couldn't build device!", :error
        end

        deferred_device.callback do |built_device|
          log "<#{self.class}> Device created."
          device_extractor.set_deferred_status(:succeeded, built_device)
        end

        deferred_device.fetch
      end

      def extract_services(service_list, group_service_extractor)
        log "<#{self.class}> Extracting services..."

        log "<#{self.class}> service list: #{service_list}"
        return if service_list.nil?

        service_list.each_value do |service|
          if service.is_a? Array
            EM::Iterator.new(service, service.count).map(
              proc do |s, iter|
                single_service_extractor = EventMachine::DefaultDeferrable.new
                single_service_extractor.callback do |service|
                  iter.return(service)
                end

                extract_service(s, single_service_extractor)
              end,
              proc do |found_services|
                group_service_extractor.set_deferred_status(:succeeded, found_services)
              end
            )
          else
            single_service_extractor = EventMachine::DefaultDeferrable.new
            single_service_extractor.callback do |service|
              group_service_extractor.set_deferred_status :succeeded, [service]
            end

            log "<#{self.class}> Extracting single service..."
            extract_service(service, single_service_extractor)
          end
        end
      end

      def extract_service(service, single_service_extractor)
        service_getter = Service.new(@url_base, service)
        log "<#{self.class}> Extracting service with #{service_getter.object_id}"

        service_getter.errback do
          log "<#{self.class}> Couldn't build service!", :error
        end

        service_getter.callback do |built_service|
          log "<#{self.class}> Service created."
          single_service_extractor.set_deferred_status(:succeeded, built_service)
        end

        service_getter.fetch
      end
    end
  end
end
