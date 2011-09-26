require_relative '../../spec_helper'
require 'upnp/ssdp/searcher'

describe "SSDP::Searcher" do
  before do
    SSDP::Connection.any_instance.stub(:set_sock_opt)
    @searcher = SSDP::Searcher.new(1, 2, 3, 4)
  end

  describe "#m_search" do
    it "builds the MSEARCH string using the given parameters" do
      @searcher.m_search("ssdp:all", 10).should == <<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: 239.255.255.250:1900\r
MAN: "ssdp:discover"\r
MX: 10\r
ST: ssdp:all\r
\r
      MSEARCH
    end
  end
end
