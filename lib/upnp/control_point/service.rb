require 'savon'
require_relative 'base'
require_relative 'error'
require_relative '../../core_ext/hash_patch'


require 'em-http'
HTTPI.adapter = :em_http
HTTPI.log = false


module UPnP
  class ControlPoint

    # An object of this type functions as somewhat of a proxy to a UPnP device's
    # service.  The object sort of defines itself when you call #fetch; it
    # gets the description file from the device, parses it, populates its
    # attributes (as accessors) and defines singleton methods from the list of
    # actions that the service defines.
    #
    # After the fetch is done, you can call Ruby methods on the service and
    # expect a Ruby Hash back as a return value.  The methods will look just
    # the SOAP actions and will always return a Hash, where key/value pairs are
    # converted from the SOAP response; values are converted to the according
    # Ruby type based on <dataType> in the <serviceStateTable>.
    #
    # Types map like:
    #   * Integer
    #     * ui1
    #     * ui2
    #     * ui4
    #     * i1
    #     * i2
    #     * i4
    #     * int
    #   * Float
    #     * r4
    #     * r8
    #     * number
    #     * fixed.14.4
    #     * float
    #   * String
    #     * char
    #     * string
    #     * uuid
    #   * TrueClass
    #     * 1
    #     * true
    #     * yes
    #   * FalseClass
    #     * 0
    #     * false
    #     * no
    #
    # @example No "in" params
    #   my_service.GetSystemUpdateID    # => { "Id" => 1 }
    #
    class Service < Base
      include EventMachine::Deferrable
      include LogSwitch::Mixin

      #vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
      # Passed in by +service_list_info+
      #

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

      #
      # DONE +service_list_info+
      #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      #vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
      # Determined by service description file
      #

      # @return [String]
      attr_reader :xmlns

      # @return [String]
      attr_reader :spec_version

      # @return [Array<Hash>]
      attr_reader :action_list

      # Probably don't need to keep this long-term; just adding for testing.
      attr_reader :service_state_table

      #
      # DONE description
      #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      # @return [Hash] The whole description... just in case.
      attr_reader :description

      # @param [String] device_base_url URL given (or otherwise determined) by
      #   <URLBase> from the device that owns the service.
      # @param [Hash] service_list_info Info given in the <serviceList> section
      #   of the device description.
      def initialize(device_base_url, service_list_info)
        @service_list_info = service_list_info
        @action_list = []
        @xmlns = ""
        extract_service_list_info(device_base_url)
        configure_savon
      end

      # Fetches the service description file, parses it, extracts attributes
      # into accessors, and defines Ruby methods from SOAP actions.  Since this
      # is a long-ish process, this is done using EventMachine Deferrable
      # behavior.
      def fetch
        if @scpd_url.empty?
          log "NO SCPDURL to get the service description from.  Returning."
          set_deferred_success self
          return
        end

        description_getter = EventMachine::DefaultDeferrable.new
        log "Fetching service description with #{description_getter.object_id}"
        get_description(@scpd_url, description_getter)

        description_getter.errback do
          msg = "Failed getting service description."
          log "#{msg}", :error
          # @todo Should this return self? or should it succeed?
          set_deferred_status(:failed, msg)

          if ControlPoint.raise_on_remote_error
            raise ControlPoint::Error, msg
          end
        end

        description_getter.callback do |description|
          log "Service description received for #{description_getter.object_id}."
          @description = description
          @xmlns = @description[:scpd][:@xmlns]
          extract_spec_version
          extract_service_state_table

          if @description[:scpd][:actionList]
            log "Defining methods from action_list using [#{description_getter.object_id}]"
            define_methods_from_actions(@description[:scpd][:actionList][:action])
          end

          set_deferred_status(:succeeded, self)
        end
      end

      private

      # Extracts all of the basic service information from the information
      # handed over from the device description about the service.  The actual
      # service description info gathering is *not* done here.
      #
      # @param [String] device_base_url The URLBase from the device.  Used to
      #   build absolute URLs for the service.
      def extract_service_list_info(device_base_url)
        @control_url = if @service_list_info[:controlURL]
          build_url(device_base_url, @service_list_info[:controlURL])
        else
          log "Required controlURL attribute is blank."
          ""
        end

        @event_sub_url = if @service_list_info[:eventSubURL]
          build_url(device_base_url, @service_list_info[:eventSubURL])
        else
          log "Required eventSubURL attribute is blank."
          ""
        end

        @service_type = @service_list_info[:serviceType]
        @service_id = @service_list_info[:serviceId]

        @scpd_url = if @service_list_info[:SCPDURL]
          build_url(device_base_url, @service_list_info[:SCPDURL])
        else
          log "Required SCPDURL attribute is blank."
          ""
        end
      end

      def extract_spec_version
        "#{@description[:scpd][:specVersion][:major]}.#{@description[:scpd][:specVersion][:minor]}"
      end

      def extract_service_state_table
        @service_state_table = if @description[:scpd][:serviceStateTable].is_a? Hash
          @description[:scpd][:serviceStateTable][:stateVariable]
        elsif @description[:scpd][:serviceStateTable].is_a? Array
          @description[:scpd][:serviceStateTable].map do |state|
            state[:stateVariable]
          end
        end
      end

      # Determines if <actionList> from the service description contains a
      # single action or multiple actions and delegates to create Ruby methods
      # accordingly.
      #
      # @param [Hash,Array] action_list The value from <scpd><actionList><action>
      #   from the service description.
      def define_methods_from_actions(action_list)
        log "Defining methods; action list: #{action_list}"

        if action_list.is_a? Hash
          @action_list << action_list
          define_method_from_action(action_list[:name].to_sym,
            action_list[:argumentList][:argument])
        elsif action_list.is_a? Array
          action_list.each do |action|
=begin
        in_args_count = action[:argumentList][:argument].find_all do |arg|
          arg[:direction] == 'in'
        end.size
=end
            @action_list << action
            args = action[:argumentList] ? action[:argumentList][:argument] : {}
            define_method_from_action(action[:name].to_sym, args)
          end
        else
          log "Got actionList that's not an Array or Hash."
        end
      end

      # Defines a Ruby method from the SOAP action.
      #
      # All resulting methods will either take no arguments or a single Hash as
      # an argument, whatever the SOAP action describes as its "in" arguments.
      # If the action describes "in" arguments, then you must provide a Hash
      # where keys are argument names and values are the values for those
      # arguments.
      #
      # For example, the GetCurrentConnectionInfo action from the
      # "ConnectionManager:1" service describes an "in" argument named
      # "ConnectionID" whose dataType is "i4".  To call this action via the
      # Ruby method, it'd look like:
      #
      #   connection_manager.GetCurrentConnectionInfo({ "ConnectionID" => 42 })
      #
      # There is currently no type checking for these "in" arguments.
      #
      # Calling that Ruby method will, in turn, call the SOAP action by the same
      # name, with the body set to:
      #
      #   <connectionID>42</connectionID>
      #
      # The UPnP device providing the service will reply with a SOAP
      # response--either a fault or with good data--and that will get converted
      # to a Hash. This Hash will contain key/value pairs defined by the "out"
      # argument names and values.  Each value is converted to an associated
      # Ruby type, determined from the serviceStateTable.  If no return data
      # is relevant for the request you made, some devices may return an empty
      # body.
      #
      # @param [Symbol] action_name The extracted value from <actionList>
      #   <action><name> from the spec.
      # @param [Hash,Array] argument_info The extracted values from
      #   <actionList><action><argumentList><argument> from the spec.
      def define_method_from_action(action_name, argument_info)
        # Do this here because, for some reason, @service_type is out of scope
        # in the #request block below.
        st = @service_type

        define_singleton_method(action_name) do |params|
          begin
            response = @soap_client.request(:u, action_name.to_s, "xmlns:u" => @service_type) do
              http.headers['SOAPACTION'] = "#{st}##{action_name}"
              soap.namespaces["s:encodingStyle"] = "http://schemas.xmlsoap.org/soap/encoding/"

              unless params.nil?
                raise ArgumentError,
                  "Method only accepts Hashes" unless params.is_a? Hash
                soap.body = params.symbolize_keys!
              end
            end
          rescue Savon::SOAP::Fault, Savon::HTTP::Error => ex
            hash = xml_parser.parse(ex.http.body)
            msg = <<-MSG
SOAP request failure!
HTTP response code: #{ex.http.code}
HTTP headers: #{ex.http.headers}
HTTP body: #{ex.http.body}
HTTP body as Hash: #{hash}
            MSG

            log "#{msg}"
            raise(ActionError, msg) if ControlPoint.raise_on_remote_error

            if hash.empty?
              return ex.http.body
            else
              return hash[:Envelope][:Body]
            end
          end

          return_value = if argument_info.is_a?(Hash) && argument_info[:direction] == "out"
            return_ruby_from_soap(action_name, response, argument_info)
          elsif argument_info.is_a? Array
            argument_info.map do |arg|
              if arg[:direction] == "out"
                return_ruby_from_soap(action_name, response, arg)
              end
            end
          else
            log "No args with direction 'out'"
            {}
          end

          return_value
        end

        log "Defined method: #{action_name}"
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

        int_types = %w[ui1 ui2 ui4 i1 i2 i4 int]
        float_types = %w[r4 r8 number fixed.14.4 float]
        string_types = %w[char string uuid]
        true_types = %w[1 true yes]
        false_types = %w[0 false no]

        if soap_response.success? && soap_response.to_xml.empty?
          log "Got successful but empty soap response!"
          return {}
        end

        if int_types.include? state_variable[:dataType]
          {
            out_arg_name.to_sym => soap_response.
              hash[:Envelope][:Body]["#{action_name}Response".to_sym][out_arg_name.to_sym].to_i
          }
        elsif string_types.include? state_variable[:dataType]
          {
            out_arg_name.to_sym => soap_response.
              hash[:Envelope][:Body]["#{action_name}Response".to_sym][out_arg_name.to_sym].to_s
          }
        elsif float_types.include? state_variable[:dataType]
          {
            out_arg_name.to_sym => soap_response.
              hash[:Envelope][:Body]["#{action_name}Response".to_sym][out_arg_name.to_sym].to_f
          }
        elsif true_types.include? state_variable[:dataType]
          {
            out_arg_name.to_sym => true
          }
        elsif false_types.include? state_variable[:dataType]
          {
            out_arg_name.to_sym => false
          }
        else
          log "Got SOAP response that I dunno what to do with: #{soap_response.hash}"
        end
      end

      def configure_savon
        @soap_client = Savon.client do |wsdl|
          wsdl.endpoint = @control_url
          wsdl.namespace = @service_type
        end

        @soap_client.config.env_namespace = :s
      end
    end
  end
end
