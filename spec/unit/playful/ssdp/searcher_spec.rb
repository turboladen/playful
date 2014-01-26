require 'spec_helper'
require 'playful/ssdp/searcher'


describe Playful::SSDP::Searcher do
  around(:each) do |example|
    EM.synchrony do
      example.run
      EM.stop
    end
  end

  before do
    Playful.log = false
    allow_any_instance_of(Playful::SSDP::MulticastConnection).to receive(:setup_multicast_socket)
  end

  subject do
    Playful::SSDP::Searcher.new(1, "ssdp:all", {})
  end

  it "lets you read its responses" do
    responses = double 'responses'
    subject.instance_variable_set(:@discovery_responses, responses)
    expect(subject.discovery_responses).to eq responses
  end

  describe "#initialize" do
    it "does an #m_search" do
      expect_any_instance_of(Playful::SSDP::Searcher).to receive(:m_search).and_return(<<-MSEARCH
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
      expect(parsed_response).to receive(:has_key?).with(:nts).and_return false
      expect(parsed_response).to receive(:[]).and_return false

      parsed_response
    end

    it "takes a response and adds it to the list of responses" do
      response = double 'response'
      allow(subject).to receive(:peer_info).and_return(['0.0.0.0', 4567])

      expect(subject).to receive(:parse).with(response).exactly(1).times.
        and_return(parsed_response)
      expect(subject.instance_variable_get(:@discovery_responses)).to receive(:<<).
        with(parsed_response)

      subject.receive_data(response)
    end
  end

  describe "#post_init" do
    before { allow_any_instance_of(Playful::SSDP::Searcher).to receive(:m_search).and_return("hi") }

    it "sends an M-SEARCH as a datagram over 239.255.255.250:1900" do
      m_search_count_times = subject.instance_variable_get(:@m_search_count)
      expect(subject).to receive(:send_datagram).
        with("hi", '239.255.255.250', 1900).
        exactly(m_search_count_times).times.
        and_return 0
      subject.post_init
    end
  end

  describe "#m_search" do
    it "builds the MSEARCH string using the given parameters" do
      expect(subject.m_search("ssdp:all", 10)).to eq <<-MSEARCH
M-SEARCH * HTTP/1.1\r
HOST: 239.255.255.250:1900\r
MAN: "ssdp:discover"\r
MX: 10\r
ST: ssdp:all\r
\r
      MSEARCH
    end

    it "uses 239.255.255.250 as the HOST IP" do
      expect(subject.m_search("ssdp:all", 10)).to match(/HOST: 239.255.255.250/m)
    end

    it "uses 1900 as the HOST port" do
      expect(subject.m_search("ssdp:all", 10)).to match(/HOST:.*1900/m)
    end

    it "lets you search for undefined search target types" do
      expect(subject.m_search("spaceship", 10)).to eq <<-MSEARCH
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

