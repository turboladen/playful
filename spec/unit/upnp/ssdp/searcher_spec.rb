require 'spec_helper'
require 'upnp/ssdp/searcher'


describe UPnP::SSDP::Searcher do
  around(:each) do |example|
    EM.run do
      example.run
      EM.stop
    end
  end

  before do
    UPnP.log = false
    UPnP::SSDP::MulticastConnection.any_instance.stub(:setup_multicast_socket)
  end

  subject do
    UPnP::SSDP::Searcher.new(1, "ssdp:all", {})
  end

  it "lets you read its responses" do
    responses = double 'responses'
    subject.instance_variable_set(:@discovery_responses, responses)
    subject.discovery_responses.should == responses
  end

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

  describe "#receive_data" do
    let(:parsed_response) do
      parsed_response = double 'parsed response'
      parsed_response.should_receive(:has_key?).with(:nts).and_return false
      parsed_response.should_receive(:[]).and_return false

      parsed_response
    end

    it "takes a response and adds it to the list of responses" do
      response = double 'response'
      subject.stub(:peer_info).and_return(['0.0.0.0', 4567])

      subject.should_receive(:parse).with(response).exactly(1).times.
        and_return(parsed_response)
      subject.instance_variable_get(:@discovery_responses).should_receive(:<<).
        with(parsed_response)

      subject.receive_data(response)
    end
  end

  describe "#post_init" do
    before { UPnP::SSDP::Searcher.any_instance.stub(:m_search).and_return("hi") }

    it "sends an M-SEARCH as a datagram over 239.255.255.250:1900" do
      m_search_count_times = subject.instance_variable_get(:@m_search_count)
      subject.should_receive(:send_datagram).
        with("hi", '239.255.255.250', 1900).
        exactly(m_search_count_times).times.
        and_return 0
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

