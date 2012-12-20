require 'log_switch'


module UPnP
  class SSDP
    extend LogSwitch

    self.logger.datetime_format = "%Y-%m-%d %H:%M:%S "
  end
end

UPnP::SSDP.log_class_name = true
