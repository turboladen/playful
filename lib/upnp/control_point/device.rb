require_relative 'base'
require_relative 'service'
require_relative 'error'
require 'uri'
require 'eventmachine'
require 'time'


module UPnP
  class ControlPoint
    class Device < Base
      include EM::Deferrable
      include LogSwitch::Mixin

      attr_reader :ssdp_notification

      #vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
      # Passed in as part of +device_info+; given by the SSDP search response.
      #
      attr_reader :cache_control
      attr_reader :date
      attr_reader :ext
      attr_reader :location
      attr_reader :server
      attr_reader :st
      attr_reader :usn
      #
      # DONE +device_info+
      #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      # @return [Hash] The whole parsed description... just in case.
      attr_reader :description

      attr_reader :expiration

      #vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
      # Determined by device description file.
      #

      #------- <root> elements -------

      # @return [String] The xmlns attribute of the device from the description file.
      attr_reader :xmlns

      # @return [Hash] :major and :minor revisions of the UPnP spec this device adheres to.
      attr_reader :spec_version

      # @return [String] URLBase from the device's description file.
      attr_reader :url_base

      #------- <root><device> elements -------

      # @return [String] The type of UPnP device (URN) from the description file.
      attr_reader :device_type

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

      # @return [String] The serial number from the description file.
      attr_reader :serial_number

      # @return [String] The UDN for the device, from the description file.
      attr_reader :udn

      # @return [String] The UPC of the device from the description file.
      attr_reader :upc

      # @return [Array<Hash>] An Array where each element is a Hash that describes an icon.
      attr_reader :icon_list

      # Services provided directly by this device.
      attr_reader :service_list

      # Devices embedded directly into this device.
      attr_reader :device_list

      # @return [String] URL for device control via a browser.
      attr_reader :presentation_url

      #
      # DONE description file
      #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      # @param [Hash] device_info
      # @option device_info [Hash] ssdp_notification
      # @option device_info [Hash] device_description
      # @option device_info [Hash] parent_base_url
      def initialize(device_info)
        super()

        @device_info = device_info
        log "<#{self.class}> Got device info: #{@device_info}"
        @device_list = []
        @service_list = []
        @icon_list = []
        @xmlns = ""
        @done_creating_devices = false
        @done_creating_services = false
      end

      def fetch
        description_getter = EventMachine::DefaultDeferrable.new

        description_getter.errback do
          msg = "Failed getting description."
          log "<#{self.class}> #{msg}", :error
          @done_creating_devices = true
          @done_creating_services = true
          set_deferred_status(:failed, msg)

          if ControlPoint.raise_on_remote_error
            raise ControlPoint::Error, msg
          end
        end

        if @device_info.has_key? :ssdp_notification
          log "<#{self.class}> Creating device from SSDP Notification info."
          @ssdp_notification = @device_info[:ssdp_notification]

          @cache_control = @ssdp_notification[:cache_control]
          @location = ssdp_notification[:location]
          @server = ssdp_notification[:server]
          @st = ssdp_notification[:st] || ssdp_notification[:nt]
          @ext = ssdp_notification.has_key?(:ext) ? true : false
          @usn = ssdp_notification[:usn]
          @date = ssdp_notification[:date] || ''
          @expiration = if @date.empty?
            Time.now + @cache_control.match(/\d+/)[0].to_i
          else
            Time.at(Time.parse(@date).to_i + @cache_control.match(/\d+/)[0].to_i)
          end

          if @location
            get_description(@location, description_getter)
          else
            message = "M-SEARCH response is either missing the Location header or has an empty value."
            message << "Response: #{@ssdp_notification}"

            if ControlPoint.raise_on_remote_error
              raise ControlPoint::Error, message
            end
          end
        elsif @device_info.has_key? :device_description
          log "<#{self.class}> Creating device from device description file info."
          description_getter.set_deferred_success @device_info[:device_description]
        else
          log "<#{self.class}> Not sure what to extract from this device's info."
          description_getter.set_deferred_failure
        end

        description_getter.callback do |description|
          log "<#{self.class}> Description received from #{description_getter.object_id}"
          @description = description

          if @description.nil?
            log "<#{self.class}> Description is empty.", :error
            set_deferred_status(:failed, "Got back an empty description...")
            return
          end

          extract_spec_version

          @url_base = extract_url_base
          log "<#{self.class}> Set url_base to #{@url_base}"

          if @device_info[:ssdp_notification]
            @xmlns = @description[:root][:@xmlns]
            log "<#{self.class}> Extracting description for root device #{description_getter.object_id}"
            extract_description(@description[:root][:device])
          elsif @device_info.has_key? :device_description
            log "<#{self.class}> Extracting description for non-root device #{description_getter.object_id}"
            extract_description(@description)
          end
        end

        tickloop = EM.tick_loop do
          if @done_creating_devices && @done_creating_services
            log "<#{self.class}> All done creating stuff"
            :stop
          end
        end

        tickloop.on_stop { set_deferred_status :succeeded, self }
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

      # True if the device hasn't received an alive notification since it last
      # told its max age.
      def expired?
        Time.now > @expiration if @expiration
      end

      def has_devices?
        !@device_list.empty?
      end

      def has_services?
        !@service_list.empty?
      end

      def extract_description(ddf)
        log "<#{self.class}> Extracting basic attributes from description..."

        @device_type = ddf[:deviceType] || ''
        @friendly_name = ddf[:friendlyName] || ''
        @manufacturer = ddf[:manufacturer] || ''
        @manufacturer_url = ddf[:manufacturerURL] || ''
        @model_description = ddf[:modelDescription] || ''
        @model_name = ddf[:modelName] || ''
        @model_number = ddf[:modelNumber] || ''
        @model_url = ddf[:modelURL] || ''
        @serial_number = ddf[:serialNumber] || ''
        @udn = ddf[:UDN] || ''
        @upc = ddf[:UPC] || ''
        @icon_list = extract_icons(ddf[:iconList])
        @presentation_url = ddf[:presentationURL] || ''

        log "<#{self.class}> Basic attributes extracted."

        start_device_extraction
        start_service_extraction
      def extract_spec_version
        "#{@description[:root][:specVersion][:major]}.#{@description[:root][:specVersion][:minor]}"
      end

      def start_service_extraction
        services_extractor = EventMachine::DefaultDeferrable.new

        if @description[:serviceList]
          log "<#{self.class}> Extracting services from non-root device."
          extract_services(@description[:serviceList], services_extractor)
        elsif @description[:root][:device][:serviceList]
          log "<#{self.class}> Extracting services from root device."
          extract_services(@description[:root][:device][:serviceList], services_extractor)
        end

        services_extractor.errback do
          msg = "Failed extracting services."
          log "<#{self.class}> #{msg}", :error
          @done_creating_services = true

          if ControlPoint.raise_on_remote_error
            raise ControlPoint::Error, msg
          end
        end

        services_extractor.callback do |services|
          log "<#{self.class}> Done extracting services."
          @service_list = services

          log "<#{self.class}> New service count: #{@service_list.size}."
          @done_creating_services = true
        end
      end

      def start_device_extraction
        device_extractor = EventMachine::DefaultDeferrable.new
        extract_devices(device_extractor)

        device_extractor.errback do
          msg = "Failed extracting device."
          log "<#{self.class}> #{msg}", :error
          @done_creating_devices = true

          if ControlPoint.raise_on_remote_error
            raise ControlPoint::Error, msg
          end
        end

        device_extractor.callback do |device|
          if device
            log "<#{self.class}> Device extracted from #{device_extractor.object_id}."
            @device_list << device
          else
            log "<#{self.class}> Device extraction done from #{device_extractor.object_id} but none were extracted."
          end

          log "<#{self.class}> Child device size is now: #{@device_list.size}"
          @done_creating_devices = true
        end
      end

      # @return [Array<Hash>]
      def extract_icons(ddf_icon_list)
        return [] unless ddf_icon_list
        log "<#{self.class}> Icon list: #{ddf_icon_list}"

        if ddf_icon_list[:icon].is_a? Array
          ddf_icon_list[:icon].map do |values|
            values[:url] = build_url(@url_base, values[:url])
            values
          end
        else
          [{
            mimetype: ddf_icon_list[:icon][:mimetype],
            width: ddf_icon_list[:icon][:width],
            height: ddf_icon_list[:icon][:height],
            depth: ddf_icon_list[:icon][:depth],
            url: build_url(@url_base, ddf_icon_list[:icon][:url])
          }]
        end
      end

      def extract_devices(group_device_extractor)
        log "<#{self.class}> Extracting child devices for #{self.object_id} using #{group_device_extractor.object_id}"

        device_list_hash = if @description.has_key? :root
          log "<#{self.class}> Description has a :root key..."

          if @description[:root][:device].has_key? :deviceList
            @description[:root][:device][:deviceList][:device]
          else
            log "<#{self.class}> No child devices to extract."
            group_device_extractor.set_deferred_status(:succeeded)
          end
        elsif @description[:deviceList]
          log "<#{self.class}> Description does not have a :root key..."
          @description[:deviceList][:device]
        else
          log "<#{self.class}> No child devices to extract."
          group_device_extractor.set_deferred_status(:succeeded)
        end

        if device_list_hash.nil? || device_list_hash.empty?
          group_device_extractor.set_deferred_status(:succeeded)
          return
        end

        log "<#{self.class}> device list: #{device_list_hash}"

        if device_list_hash.is_a? Array
          EM::Iterator.new(device_list_hash, device_list_hash.count).map(
            proc do |device, iter|
              single_device_extractor = EventMachine::DefaultDeferrable.new

              single_device_extractor.errback do
                msg = "Failed extracting device."
                log "<#{self.class}> #{msg}", :error

                if ControlPoint.raise_on_remote_error
                  raise ControlPoint::Error, msg
                end
              end

              single_device_extractor.callback do |device|
                iter.return(device)
              end

              extract_device(device, single_device_extractor)
            end,
            proc do |found_devices|
              group_device_extractor.set_deferred_status(:succeeded, found_devices)
            end
          )
        else
          single_device_extractor = EventMachine::DefaultDeferrable.new

          single_device_extractor.errback do
            msg = "Failed extracting device."
            log "<#{self.class}> #{msg}", :error
            group_device_extractor.set_deferred_status(:failed, msg)

            if ControlPoint.raise_on_remote_error
              raise ControlPoint::Error, msg
            end
          end

          single_device_extractor.callback do |device|
            group_device_extractor.set_deferred_status(:succeeded, [device])
          end

          log "<#{self.class}> Extracting single device..."
          extract_device(device_list_hash, group_device_extractor)
        end
      end

      def extract_device(device, device_extractor)
        deferred_device = Device.new(device_description: device, parent_base_url: @url_base)

        deferred_device.errback do
          msg = "Couldn't build device!"
          log "<#{self.class}> #{msg}", :error
          device_extractor.set_deferred_status(:failed, msg)

          if ControlPoint.raise_on_remote_error
            raise ControlPoint::Error, msg
          end
        end

        deferred_device.callback do |built_device|
          log "<#{self.class}> Device created: #{built_device.device_type}"
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

                single_service_extractor.errback do
                  msg = "Failed to create service."
                  log "<#{self.class}> #{msg}", :error

                  if ControlPoint.raise_on_remote_error
                    raise ControlPoint::Error, msg
                  end
                end

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

            single_service_extractor.errback do
              msg = "Failed to create service."
              log "<#{self.class}> #{msg}", :error
              group_service_extractor.set_deferred_status :failed, msg

              if ControlPoint.raise_on_remote_error
                raise ControlPoint::Error, msg
              end
            end

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

        service_getter.errback do |message|
          msg = "Couldn't build service with info: #{service}"
          log "<#{self.class}> #{msg}", :error
          single_service_extractor.set_deferred_status(:failed, msg)

          if ControlPoint.raise_on_remote_error
            raise ControlPoint::Error, message
          end
        end

        service_getter.callback do |built_service|
          log "<#{self.class}> Service created: #{built_service.service_type}"
          single_service_extractor.set_deferred_status(:succeeded, built_service)
        end

        service_getter.fetch
      end
    end
  end
end
