require 'spec_helper'
require 'upnp/ssdp/searcher'

describe UPnP::SSDP::Searcher do
  def prepped_searcher
    UPnP::SSDP::Searcher.any_instance.stub(:set_sock_opt)
    UPnP::SSDP::Searcher.any_instance.should_receive(:setup_multicast_socket)
    UPnP::SSDP::Searcher.any_instance.stub(:send_datagram).and_return(1)
    UPnP::SSDP::Searcher.new(1, "ssdp:all", 5, 4)
  end

  subject { prepped_searcher }

  before { UPnP::SSDP.log = false }

  describe "#initialize" do
    it "does an #m_search" do
      UPnP::SSDP::Searcher.any_instance.should_receive(:m_search).and_return(<<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: 239.255.255.250:1900\r
MAN: "ssdp:discover"\r
MX: 5\r
ST: ssdp:all\r
\r
      MSEARCH
      )
      subject
    end
  end

  describe "#post_init" do
    before { UPnP::SSDP::Searcher.any_instance.stub(:m_search).and_return("hi") }

    it "sends an M-SEARCH as a datagram over 239.255.255.250:1900" do
      subject.should_receive(:send_datagram).with("hi", '239.255.255.250', 1900)
      subject.post_init
    end

    it "logs the M-SEARCH that it sent" do
      UPnP::SSDP.should_receive(:log).with("Sent datagram search:\nhi").at_least(:once)
      subject.post_init
    end
  end

  describe "#m_search" do
    it "builds the MSEARCH string using the given parameters" do
      subject.m_search("ssdp:all", 10).should == <<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: 239.255.255.250:1900\r
MAN: "ssdp:discover"\r
MX: 10\r
ST: ssdp:all\r
\r
      MSEARCH
    end

    it "uses 239.255.255.250 as the HOST IP" do
      subject.m_search("ssdp:all", 10).should match(/HOST: 239.255.255.250/m)
    end

    it "uses 1900 as the HOST port" do
      subject.m_search("ssdp:all", 10).should match(/HOST:.*1900/m)
    end

    it "lets you search for undefined search target types" do
      subject.m_search("spaceship", 10).should == <<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: 239.255.255.250:1900\r
MAN: "ssdp:discover"\r
MX: 10\r
ST: spaceship\r
\r
      MSEARCH
    end
  end
end

