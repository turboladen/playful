Given /^I have a non-local IP address$/ do
  @local_ip, @port = local_ip_and_port
  @local_ip.should_not be_nil
  @local_ip.should_not match /^127.0.0/
end

Given /^a UDP port on that IP is free$/ do
  @port.should_not be_nil
end
