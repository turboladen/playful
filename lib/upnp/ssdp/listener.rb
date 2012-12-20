require_relative 'multicast_connection'


class UPnP::SSDP::Listener < UPnP::SSDP::MulticastConnection

  # @return [EventMachine::Channel] Provides subscribers with notifications
  #   from devices that have come online (sent +ssdp:alive+ notifications).
  attr_reader :alive_notifications

  # @return [EventMachine::Channel] Provides subscribers with notifications
  #   from devices that have gone offline (sent +ssd:byebye+ notifications).
  attr_reader :byebye_notifications

  # This is the callback called by EventMachine when it receives data on the
  # socket that's been opened for this connection.  In this case, the method
  # parses the SSDP notifications into Hashes and adds them to the
  # appropriate EventMachine::Channel (provided as accessor methods).  This
  # effectively means that in each Channel, you get a Hash that represents
  # the headers for each notification that comes in on the socket.
  #
  # @param [String] response The data received on this connection's socket.
  def receive_data(response)
    ip, port = peer_info
    UPnP::SSDP.log "<#{self.class}> Response from #{ip}:#{port}:\n#{response}\n"
    parsed_response = parse(response)

    return unless parsed_response.has_key? :nts

    if parsed_response[:nts] == "ssdp:alive"
      @alive_notifications << parsed_response
    elsif parsed_response[:nts] == "ssdp:byebye"
      @byebye_notifications << parsed_response
    else
      raise "Unknown NTS value: #{parsed_response[:nts]}"
    end
  end
end
