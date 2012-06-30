require 'savon'


Savon.configure do |c|
  c.env_namespace = :s
end


module UPnP
  class ControlPoint
    class Service

      # @return [String] UPnP service type, including URN.
      attr_reader :service_type

      # @return [String] Service identifier, unique within this service's devices.
      attr_reader :service_id

      # @return [URI::HTTP] Service description URL.
      attr_reader :scpd_url

      # @return [URI::HTTP] Control URL.
      attr_reader :control_url

      # @return [URI::HTTP] Eventing URL.
      attr_reader :event_sub_url

      # @return [Hash<String,Array<String>>]
      attr_reader :actions

      # @return [URI::HTTP] Base URL for this service's device.
      attr_reader :device_base_url

      attr_reader :description

      def initialize(device_base_url, device_service)
        @device_base_url = device_base_url
        @scpd_url = build_url(@device_base_url, device_service[:SCPDURL])
        @control_url = build_url(@device_base_url, device_service[:controlURL])
        @event_sub_url = build_url(@device_base_url, device_service[:eventSubURL])

        @service_type = device_service[:serviceType]
        @service_id = device_service[:serviceId]

        @description = get_description(@scpd_url)
        define_methods_from_actions(@description[:scpd][:actionList][:action])

        @soap_client = Savon.client do |wsdl|
          wsdl.endpoint = @control_url
          wsdl.namespace = @service_type
        end
      end

      private

      def define_methods_from_actions(action_list)
        action_list.each do |action|
=begin
        in_args_count = action[:argumentList][:argument].find_all do |arg|
          arg[:direction] == 'in'
        end.size
=end
          define_singleton_method(action[:name].to_sym) do |*params|
            st = @service_type

            @soap_client.request(:u, action[:name], "xmlns:u" => @service_type) do
              http.headers['SOAPACTION'] = "#{st}##{action[:name]}"

              soap.body = params.inject({}) do |result, arg|
                puts "arg: #{arg}"
                result[:argument_name] = arg

                result
              end
            end
          end
        end
      end

      def get_description(location)
        Nori.parse(open(location).read)
      end

      def build_url(url_base, scpdurl)
        if url_base.end_with?('/') && scpdurl.start_with?('/')
          scpdurl.sub!('/', '')
        end

        url_base + scpdurl
      end
    end
  end
end
