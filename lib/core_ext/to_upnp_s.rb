class Hash

  # Converts Hash search targets to SSDP search target String.  Conversions are
  # as follows:
  #   uuid: "someUUID"                 # => "uuid:someUUID"
  #   device_type: "someDeviceType:1"    # => "urn:schemas-upnp-org:device:someDeviceType:1"
  #   service_type: "someServiceType:2"  # => "urn:schemas-upnp-org:service:someServiceType:2"
  #
  # You can use custom UPnP domain names too:
  #   { device_type: "someDeviceType:3",
  #   domain_name: "mydomain-com" }    # => "urn:my-domain:device:someDeviceType:3"
  #   { service_type: "someServiceType:4",
  #   domain_name: "mydomain-com" }    # => "urn:my-domain:service:someDeviceType:4"
  #
  # @return [String] The converted String, according to the UPnP spec.
  def to_upnp_s
    if self.has_key? :uuid then
      return "uuid:#{self[:uuid]}"
    elsif self.has_key? :device_type
      if self.has_key? :domain_name
        return "urn:#{self[:domain_name]}:device:#{self[:device_type]}"
      else
        return "urn:schemas-upnp-org:device:#{self[:device_type]}"
      end
    elsif self.has_key? :service_type
      if self.has_key? :domain_name
        return "urn:#{self[:domain_name]}:service:#{self[:service_type]}"
      else
        return "urn:schemas-upnp-org:service:#{self[:service_type]}"
      end
    else
      self.to_s
    end
  end
end


class Symbol

  # Converts Symbol search targets to SSDP search target String.  Conversions are
  # as follows:
  #   :all    # => "ssdp:all"
  #   :root   # => "upnp:rootdevice"
  #   "root"  # => "upnp:rootdevice"
  #
  # @return [String] The converted String, according to the UPnP spec.
  def to_upnp_s
    if self == :all
      "ssdp:all"
    elsif self == :root
      "upnp:rootdevice"
    else
      self
    end
  end
end


class String
  # This doesn't do anything to the string; just allows users to call the
  # method without having to check type first.
  def to_upnp_s
    self
  end
end
