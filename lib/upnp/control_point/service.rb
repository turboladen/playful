require 'savon'
require_relative 'base'
require_relative 'error'


Savon.configure do |c|
  c.env_namespace = :s
end

begin
  require 'em-http'
  HTTPI.adapter = :em_http
rescue ArgumentError
  puts "Couldn't load HTTPI :em_http adapter."
  # Fail silently
end


module UPnP
  class ControlPoint
    class Service < Base
      include EventMachine::Deferrable
      include LogSwitch::Mixin

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

      # Probably don't need to keep this long-term; just adding for testing.
      attr_reader :service_state_table

      def initialize(device_base_url, device_service)
        @device_base_url = device_base_url
        @device_service = device_service
        @actions = []

        if @device_service[:controlURL]
          @control_url = build_url(@device_base_url, @device_service[:controlURL])
        end

        if @device_service[:eventSubURL]
          @event_sub_url = build_url(@device_base_url, @device_service[:eventSubURL])
        end

        @service_type = @device_service[:serviceType]
        @service_id = @device_service[:serviceId]
        return unless @device_service[:SCPDURL]

        @scpd_url = build_url(@device_base_url, @device_service[:SCPDURL])
      end

      def fetch
        if @scpd_url.nil?
          log "<#{self.class}> NO SCPDURL to get the service description from.  Returning."
          log "<#{self.class}> Device service info: #{@device_service}"
          set_deferred_success self
          return
        end

        description_getter = EventMachine::DefaultDeferrable.new
        log "<#{self.class}> Fetching service description with #{description_getter.object_id}"
        get_description(@scpd_url, description_getter)

        description_getter.errback do
          msg = "Failed getting service description."
          log "<#{self.class}> #{msg}", :error
          set_deferred_status(:failed, msg)

          if ControlPoint.raise_on_remote_error
            raise ControlPoint::Error, msg
          end
        end

        description_getter.callback do |description|
          log "<#{self.class}> Service description received for #{description_getter.object_id}."
          @description = description

          @service_state_table = if @description[:scpd][:serviceStateTable].is_a? Hash
            @description[:scpd][:serviceStateTable][:stateVariable]
          elsif @description[:scpd][:serviceStateTable].is_a? Array
            @description[:scpd][:serviceStateTable].map do |state|
              state[:stateVariable]
            end
          end

          if @description[:scpd][:actionList]
            log "<#{self.class}> Defining methods from actions [#{description_getter.object_id}]"
            define_methods_from_actions(@description[:scpd][:actionList][:action])

            @soap_client = Savon.client do |wsdl|
              wsdl.endpoint = @control_url
              wsdl.namespace = @service_type
            end
          end

          set_deferred_status(:succeeded, self)
        end
      end

      private

      # @param [Symbol] action_name The extracted value from <actionList>
      #   <action><name> from the spec.
      # @param [Hash,Array] argument_info The extracted values from
      #   <actionList><action><argumentList><argument> from the spec.
      def define_method_from_action(action_name, argument_info)
        define_singleton_method(action_name) do |*params|
          st = @service_type

          begin
            response = @soap_client.request(:u, action_name, "xmlns:u" => @service_type) do
              http.headers['SOAPACTION'] = "#{st}##{action_name}"

              soap.body = params.inject({}) do |result, arg|
                log "<#{self.class}> arg: #{arg}"
                result[:argument_name] = arg

                result
              end
            end
          rescue Savon::SOAP::Fault => ex
            # Should raise an ActionError or something that relates to the
            # spec
            hash = Nori.parse(ex.http.body)
            msg = "Received bad HTTP response code (#{ex.http.code})\n" +
              "#{ex.http.headers}\n#{ex.http.body}\n#{hash}"
            if ControlPoint.raise_on_remote_error
              raise Error, msg
            else
              log "<#{self.class}> #{msg}"
              return hash
            end
          end

          if argument_info.is_a?(Hash) && argument_info[:direction] == "out"
            return_ruby_from_soap(action_name, response, argument_info)
          elsif argument.is_a? Array
            argument_info.map do |a|
              if a[:direction] == "out"
                return_ruby_from_soap(action_name, response, a)
              end
            end
          else
            puts "No args with direction 'out'"
          end
        end
      end

      def define_methods_from_actions(action_list)
        if action_list.is_a? Hash
          action = action_list
          define_method_from_action(action[:name].to_sym, action[:argumentList][:argument])
        elsif action_list.is_a? Array
          action_list.each do |action|
=begin
        in_args_count = action[:argumentList][:argument].find_all do |arg|
          arg[:direction] == 'in'
        end.size
=end
            @actions << action
            define_method_from_action(action[:name].to_sym, action[:argumentList][:argument])
          end
        end
      end

      # Uses the serviceStateTable to look up the output from the SOAP response
      # for the given action, then converts it to the according Ruby data type.
      #
      # @param [String] action_name The name of the SOAP action that was called
      #   for which this will get the response from.
      # @param [Savon::SOAP::Response] soap_response The response from making
      #   the SOAP call.
      # @param [Hash] out_argument The Hash that tells out the "out" argument
      #   which tells what data type to return.
      # @return [Hash] Key will be the "out" argument name as a Symbol and the
      #   key will be the value as its converted Ruby type.
      def return_ruby_from_soap(action_name, soap_response, out_argument)
        out_arg_name = out_argument[:name]
        #puts "out arg name: #{out_arg_name}"

        related_state_variable = out_argument[:relatedStateVariable]
        #puts "related state var: #{related_state_variable}"

        state_variable = @service_state_table.find do |state_var_hash|
          state_var_hash[:name] == related_state_variable
        end

        #puts "state var: #{state_variable}"

        int_types = %w[ui1 ui2 ui4 i1 i2 i4 in]
        float_types = %w[r4 r8 number fixed.14.4 float]
        string_types = %w[char string uuid]
        true_types = %w[1 true yes]
        false_types = %w[0 false no]

        if int_types.include? state_variable[:dataType]
          {
            out_arg_name.to_sym => soap_response.
              hash[:Envelope][:Body]["#{action_name}Response".to_sym][out_arg_name.to_sym].to_i
          }
        elsif string_types.include? state_variable[:dataType]
          return {} if soap_response.hash.empty?
          {
            out_arg_name.to_sym => soap_response.
              hash[:Envelope][:Body]["#{action_name}Response".to_sym][out_arg_name.to_sym].to_s
          }
        elsif float_types.include? state_variable[:dataType]
          {
            out_arg_name.to_sym => soap_response.
              hash[:Envelope][:Body]["#{action_name}Response".to_sym][out_arg_name.to_sym].to_f
          }
        else
          log "<#{self.class}> Got SOAP response that I dunno what to do with: #{soap_response.hash}"
        end
      end
    end
  end
end
