require_relative '../spec_helper'

describe SSDP do
  #describe '.listen' do
  #  it 'starts the EM reactor' do
  #    begin
  #      Thread.new { SSDP.listen }
  #      sleep 1
  #      EM.reactor_running?.should be_true
  #    ensure
  #      EM.stop if EM.reactor_running?
  #    end
  #  end
  #end

  describe '.search' do
    context "by default" do
      it "searches for 'ssdp:all'" do
        pending
      end

      it "waits for 5 seconds for responses" do
        before = Time.now

        SSDP.search

        after = Time.now
        (after - before).should < 5.1
        (after - before).should > 5.0
      end
    end

    context "finds 'upnp:rootdevice's" do
      it "by using the spec's string 'upnp:rootdevice'" do
        SSDP.search('upnp:rootdevice').should == [
          {
            :cache_control=>"max-age=1200",
            :date=>"Mon, 26 Sep 2011 06:40:19 GMT",
            :location=>"http://192.168.10.3:5001/description/fetch",
            :server=>"Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1",
            :st=>"upnp:rootdevice",
            :ext=>"",
            :usn=>"uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice",
            :content_length=>"0"
          }
        ]
      end

      it "by using :root" do
        pending
      end
    end

    it "can wait for user-defined seconds for responses" do
      before = Time.now

      SSDP.search(:all, 1)

      after = Time.now
      (after - before).should < 1.1
      (after - before).should > 1.0
    end

    it "finds a device by its URN" do
      pending
    end

    it "finds a device by its UUID" do
      pending
    end

    it "finds a device by its UPnP device type" do
      pending
    end

    it "finds a device by its UPnP device type using a non-standard domain name" do
      pending
    end

    it "finds a service by its UPnP service type" do
      pending
    end

    it "find a service by its UPnP service type using a non-standard domain name" do
      pending
    end
  end
end
