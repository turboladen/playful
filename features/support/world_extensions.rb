module HelperStuff
  def control_point
    @control_point ||= UPnP::ControlPoint.new
  end

  def fake_device_collection
    @fake_device_collection ||= FakeUPnPDeviceCollection.instance
  end
end

World(HelperStuff)
