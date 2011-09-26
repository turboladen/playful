require_relative '../core_ext/socket_patch'
require 'eventmachine'

require_relative 'ssdp/listener'
require_relative 'ssdp/searcher'

class SSDP

  # Default broadcast address
  BROADCAST = '239.255.255.250'

  # Default multicast port
  MULTICAST_PORT = 1900

  # Default TTL
  TTL = 4

  # Simply open a multicast UDP socket and listen for data.
  #def self.listen(ttl=TTL)
  #  EM.run do
  #    EM.open_datagram_socket(BROADCAST, MULTICAST_PORT, SSDP::Listener, ttl)
  #    i = 0
  #    EM.add_periodic_timer(1) { i += 1; print "listening for \b#{i}"}
  #    trap_signals
  #  end
  #end

  # Opens a UDP socket on 0.0.0.0, on an ephemeral port, has SSDP::Searcher
  # build and send the search request, then receives the responses.  The search
  # will stop after +response_wait_time+.
  #
  # @param [String] search_target
  # @param [Fixnum] response_wait_time
  # @param [Fixnum] ttl
  # @param [Array] An Array of all of the responses received from the request.
  def self.search(search_target="ssdp:all", response_wait_time=5, ttl=TTL)
    responses = []
    search_target = search_target_to_s(search_target) unless search_target.is_a? String

    EM.run do
      s = EM.open_datagram_socket('0.0.0.0', 0, SSDP::Searcher, search_target,
        response_wait_time, ttl)
      EM.add_shutdown_hook { responses = s.responses }
      EM.add_timer(response_wait_time) { EM.stop }
      trap_signals
    end

    responses
  end

  def self.trap_signals
    trap 'INT' do
      EM.stop
    end

    trap 'TERM' do
      EM.stop
    end
  end

  # Converts non-String search targets to String.
  #
  # @param [Hash,Symbo] st The search target to convert.
  # @return [String] The converted String, according to the UPnP spec.
  def self.search_target_to_s(st)
    if st.is_a? Hash
      if st.has_key? :uuid then
        return "uuid:#{st[:uuid]}"
      elsif st.has_key? :device_type
        if st.has_key? :domain_name
          return "urn:#{st[:domain_name]}:device:#{st[:device_type]}"
        else
          return "urn:schemas-upnp-org:device:#{st[:device_type]}"
        end
      elsif st.has_key? :service_type
        if st.has_key? :domain_name
          return "urn:#{st[:domain_name]}:service:#{st[:service_type]}"
        else
          return "urn:schemas-upnp-org:service:#{st[:service_type]}"
        end
      end
    end

    case st
    when :all then
      return "ssdp:all"
    when :root then
      return "upnp:rootdevice"
    when "root" then
      return "upnp:rootdevice"
    end
  end
end

