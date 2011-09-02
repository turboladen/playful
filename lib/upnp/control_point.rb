require 'ipaddr'
require_relative '../core_ext/socket_patch'
require 'eventmachine'

class UPnP::ControlPoint
  def initialize(ip, port)
    @ip = ip
    @port = port
  end

  def start

  end
end
