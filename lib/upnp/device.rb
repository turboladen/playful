class UPnP::Device

  # @param [String] ip
  # @param [String,Fixnum] port UDP port to talk over.
  def initialize(ip, port)
    @ip = ip
    @port = port
  end

  # Multicasts discovery messages to advertise its root device, any embedded
  # devices, and any services.
  def start
    
  end
end
