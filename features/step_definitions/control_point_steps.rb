When /^I create my control point$/ do
  @control_point = UPnP::ControlPoint.new
end

When /^tell it to find all root devices$/ do
  @control_point.find_devices(:root, 5)
end

When /^tell it to find all services$/ do
  @control_point.find_services
end

Then /^it gets a list of root devices$/ do
  @control_point.devices.should_not be_empty
end

Then /^it gets a list of services$/ do
  @control_point.services.should_not be_empty
end
