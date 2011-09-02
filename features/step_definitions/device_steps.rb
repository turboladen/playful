Given /^I have a non-local IP address$/ do
  @local_ip, @port = local_ip_and_port
  puts @local_ip
  @local_ip.should_not be_nil
  @local_ip.should_not match /^127.0.0/
end

Given /^a UDP port on that IP is free$/ do
  @port.should_not be_nil
end

When /^I start my device on that IP address and port$/ do
  @device = UPnP::Device.new(@local_ip, @port)
  @device.start.should be_true
end

Then /^the device multicasts a discovery message$/ do
  pending # express the regexp above with the code you wish you had
end

Given /^I don't have an IP address$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I start the device$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I get an error message saying I don't have an IP address$/ do
  pending # express the regexp above with the code you wish you had
end

Given /^I have a local\-link IP address$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^the device starts running normally$/ do
  pending # express the regexp above with the code you wish you had
end
