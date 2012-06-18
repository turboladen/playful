require 'spec_helper'
require_relative '../support/search_responses'
require 'upnp/control_point'

describe UPnP::ControlPoint do
  describe "#initialize" do
    context "default parameters" do
      before { @cp = UPnP::ControlPoint.new }

      it "sets @ip to '0.0.0.0'" do
        ip = @cp.instance_variable_get :@ip
        ip.should eq '0.0.0.0'
      end

      it "sets @port to 0" do
        ip = @cp.instance_variable_get :@port
        ip.should eq 0
      end
    end
  end

  describe "#find_devices" do
    context "search type = ssdp:all" do
      before do
        responses = SSDP_SEARCH_RESPONSES_PARSED.each_value.to_a
        SSDP.should_receive(:search).with("ssdp:all").and_return responses
        @cp = UPnP::ControlPoint.new

        # FIX THIS to return valid descriptions!
        @cp.should_receive(:get_description).exactly(3).times.and_return ""
      end

      it "gets all device types to @devices" do
        @cp.find_devices("ssdp:all")
        @cp.devices.should == [
          { :cache_control=>"max-age=1200", :date=>"Mon, 26 Sep 2011 06:40:19 GMT", :location=>"http://192.168.10.3:5001/description/fetch", :server=>"Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1", :st=>"upnp:rootdevice", :ext=>nil, :usn=>"uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice", :content_length=>0, :description=>"" },
          { :cache_control=>"max-age=1200", :date=>"Mon, 26 Sep 2011 06:40:20 GMT", :location=>"http://192.168.10.4:5001/description/fetch", :server=>"Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1", :st=>"upnp:rootdevice", :ext=>nil, :usn=>"uuid:3c202906-992d-3f0f-b94c-90e1902a136e::upnp:rootdevice", :content_length=>0, :description=>"" },
          { :cache_control=>"max-age=1200", :date=>"Mon, 26 Sep 2011 06:40:21 GMT", :location=>"http://192.168.10.3:5001/description/fetch", :server=>"Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1", :st=>"urn:schemas-upnp-org:device:MediaServer:1", :ext=>nil, :usn=>"uuid:3c202906-992d-3f0f-b94c-90e1902a136d::urn:schemas-upnp-org:device:MediaServer:1", :content_length=>0, :description=>"" }
        ]
      end
    end

    context "search type = upnp:rootdevice" do
      before do
        responses = SSDP_SEARCH_RESPONSES_PARSED.each_value.find_all do |r|
          r[:st] == "upnp:rootdevice"
        end.to_a
        SSDP.should_receive(:search).with("upnp:rootdevice").and_return responses
        @cp = UPnP::ControlPoint.new

        # FIX THIS to return valid descriptions!
        @cp.should_receive(:get_description).exactly(2).times.and_return ""
      end

      it "gets all device types to @devices" do
        @cp.find_devices("upnp:rootdevice")
        @cp.devices.should == [
          { :cache_control=>"max-age=1200", :date=>"Mon, 26 Sep 2011 06:40:19 GMT", :location=>"http://192.168.10.3:5001/description/fetch", :server=>"Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1", :st=>"upnp:rootdevice", :ext=>nil, :usn=>"uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice", :content_length=>0, :description=>"" },
          { :cache_control=>"max-age=1200", :date=>"Mon, 26 Sep 2011 06:40:20 GMT", :location=>"http://192.168.10.4:5001/description/fetch", :server=>"Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1", :st=>"upnp:rootdevice", :ext=>nil, :usn=>"uuid:3c202906-992d-3f0f-b94c-90e1902a136e::upnp:rootdevice", :content_length=>0, :description=>"" }
        ]
      end
    end
  end

  describe "#find_services" do
    it "sets @services to an empty Array if @devices is empty" do
      cp = UPnP::ControlPoint.new
      cp.find_services
      cp.services.should be_empty
    end
  end
end
