require_relative '../support/fake_upnp_device_collection'
require 'cucumber/rspec/doubles'

Thread.abort_on_exception = true
SSDP.log = false

Given /^there's at least (\d+) root device in my network$/ do |device_count|
  fake_device_collection.respond_with = <<-ROOT_DEVICE
HTTP/1.1 200 OK\r
CACHE-CONTROL: max-age=1200\r
DATE: Mon, 26 Sep 2011 06:40:19 GMT\r
LOCATION: http://#{local_ip}:4567\r
SERVER: Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1\r
ST: upnp:rootdevice\r
EXT:\r
USN: uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice\r
Content-Length: 0\r

  ROOT_DEVICE

  Thread.start { fake_device_collection.start_ssdp_listening }
  Thread.start { fake_device_collection.start_serving_description }
  sleep 0.2
end

When /^I come online$/ do
  control_point.should be_a UPnP::ControlPoint
end

Then /^I should discover at least (\d+) root device$/ do |device_count|
  control_point.find_devices(:root)
  fake_device_collection.stop_ssdp_listening
  fake_device_collection.stop_serving_description
  control_point.devices.should have_at_least(device_count.to_i).items
end

Then /^the location of that device should match my fake device's location$/ do
  locations = control_point.devices.map { |device| device[:location] }
  locations.should include "http://#{local_ip}:4567"
end
