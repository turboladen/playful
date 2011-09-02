When /^I start my control point$/ do
  @control_point = UPnP::ControlPoint.new(@ip, @port)
  @control_point.start.should be_true
end

Then /^it multicasts a discovery message searching for devices$/ do
  pending # express the regexp above with the code you wish you had
end
