require 'spec_helper'
require 'core_ext/to_upnp_s'


describe Hash do
  describe '#to_upnp_s' do
    context ":uuid as key" do
      it "returns a String like 'uuid:[Hash value]'" do
        { uuid: "12345" }.to_upnp_s.should == "uuid:12345"
      end

      it "doesn't check if the Hash value is legit" do
        { uuid: "" }.to_upnp_s.should == "uuid:"
      end
    end

    context ":device_type as key" do
      context "domain name not given" do
        it "returns a String like 'urn:schemas-upnp-org:device:[device type]'" do
          { device_type: "12345" }.to_upnp_s.should ==
            "urn:schemas-upnp-org:device:12345"
        end

        it "doesn't check if the Hash value is legit" do
          { device_type: "" }.to_upnp_s.should == "urn:schemas-upnp-org:device:"
        end
      end

      context "domain name given" do
        it "returns a String like 'urn:[domain name]:device:[device type]'" do
          { device_type: "12345", domain_name: "my-domain" }.to_upnp_s.should ==
            "urn:my-domain:device:12345"
        end

        it "doesn't check if the Hash value is legit" do
          { device_type: "", domain_name: "stuff" }.to_upnp_s.should ==
            "urn:stuff:device:"
        end
      end
    end

    context ":service_type as key" do
      context "domain name not given" do
        it "returns a String like 'urn:schemas-upnp-org:service:[service type]'" do
          { service_type: "12345" }.to_upnp_s.should ==
            "urn:schemas-upnp-org:service:12345"
        end

        it "doesn't check if the Hash value is legit" do
          { service_type: "" }.to_upnp_s.should == "urn:schemas-upnp-org:service:"
        end
      end

      context "domain name given" do
        it "returns a String like 'urn:[domain name]:service:[service type]'" do
          { service_type: "12345", domain_name: "my-domain" }.to_upnp_s.should ==
            "urn:my-domain:service:12345"
        end

        it "doesn't check if the Hash value is legit" do
          { service_type: "", domain_name: "my-domain" }.to_upnp_s.should ==
            "urn:my-domain:service:"
        end
      end
    end

    context "some other Hash key" do
      context "domain name not given" do
        it "returns self.to_s" do
          { firestorm: 12345 }.to_upnp_s.should == "{:firestorm=>12345}"
        end
      end
    end
  end
end

describe Symbol do
  context ":all" do
    describe "#to_upnp_s" do
      it "returns 'ssdp:all'" do
        :all.to_upnp_s.should == "ssdp:all"
      end
    end
  end

  context ":root" do
    describe "#to_upnp_s" do
      it "returns 'upnp:rootdevice'" do
        :root.to_upnp_s.should == "upnp:rootdevice"
      end
    end
  end

  it "returns itself if one of the defined shortcuts wasn't given" do
    :firestorm.to_upnp_s.should == :firestorm
  end
end

describe String do
  it "returns itself" do
    "Stuff and things".to_upnp_s.should == "Stuff and things"
  end
end


