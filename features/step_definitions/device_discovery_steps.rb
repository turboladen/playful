require_relative '../support/fake_upnp_device_collection'
require 'cucumber/rspec/doubles'

Thread.abort_on_exception = true

Given /^there's at least (\d+) root device in my network$/ do |device_count|
  fake_device_collection.response = <<-ROOT_DEVICE
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=1200
DATE: Mon, 26 Sep 2011 06:40:19 GMT
LOCATION: http://1.2.3.4:5678/description/fetch
SERVER: Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1
ST: upnp:rootdevice
EXT:
USN: uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice
Content-Length: 0

  ROOT_DEVICE

  fake_device_collection.start
  sleep 0.2
end

When /^I come online$/ do
  control_point.should be_a UPnP::ControlPoint
end

Then /^I should discover at least (\d+) root device$/ do |device_count|
  control_point.find_devices("upnp:rootdevice")
  fake_device_collection.stop
  control_point.devices.should have_at_least(device_count.to_i).items
end

Then /^the location of that device should match my fake device's location$/ do
  locations = control_point.devices.map { |device| device[:location] }
  locations.should include "http://1.2.3.4:5678/description/fetch"
end
