module Playful
  class ControlPoint
    class Error < StandardError
      #
    end

    # Indicates an error occurred when performing a UPnP action while controlling
    # a device.  See section 3.2 of the UPnP spec.
    class ActionError < StandardError
      #
    end
  end
end
