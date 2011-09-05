require_relative 'ssdp'

module UPnP
  class ControlPoint
    attr_reader :devices

    def initialize(ip='0.0.0.0', port=0)
      @ip = ip
      @port = port
      @devices = []
    end

    def start
      @devices = SSDP.search("ssdp:all")
      @devices = SSDP.search "upnp:rootdevice" if @devices.empty?
    end
  end
end
