require 'spec_helper'
require 'ssdp/connection'

describe "SSDP::Connection" do
  def prepped_connection
    SSDP::Connection.any_instance.stub(:set_sock_opt)
    SSDP::Connection.new(1)
  end

  subject { prepped_connection }

  before { SSDP.log = false }

  it "lets you read its responses" do
    responses = double 'responses'
    subject.instance_variable_set(:@discovery_responses, responses)
    subject.discovery_responses.should == responses
  end

  describe "#peer_info" do
    before do
      subject.stub_chain(:get_peername, :[], :unpack).and_return(["1234",
        "1", "2", "3", "4"])
    end

    it "returns an Array with IP and port" do
      subject.peer_info.should == ['1.2.3.4', 1234]
    end

    it "returns IP as a String" do
      subject.peer_info.first.should be_a String
    end

    it "returns port as a Fixnum" do
      subject.peer_info.last.should be_a Fixnum
    end
  end

  describe "#receive_data" do
    it "takes a response and adds it to the list of responses" do
      response = double 'response'
      parsed_response = double 'parsed response'
      subject.should_receive(:parse).with(response).exactly(1).times.
        and_return(parsed_response)
      subject.should_receive(:peer_info).at_least(:once).
        and_return(['0.0.0.0', 4567])
      subject.receive_data(response)
      subject.discovery_responses.should == [parsed_response]
    end
  end

  describe "#parse" do
    it "turns headers into Hash keys" do
      result = subject.parse ROOT_DEVICE1
      result.should have_key :cache_control
      result.should have_key :date
      result.should have_key :location
      result.should have_key :server
      result.should have_key :st
      result.should have_key :ext
      result.should have_key :usn
      result.should have_key :content_length
    end

    it "turns header values into Hash values" do
      result = subject.parse ROOT_DEVICE1
      result[:cache_control].should == "max-age=1200"
      result[:date].should == "Mon, 26 Sep 2011 06:40:19 GMT"
      result[:location].should == "http://1.2.3.4:5678/description/fetch"
      result[:server].should == "Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1"
      result[:st].should == "upnp:rootdevice"
      result[:ext].should be_empty
      result[:usn].should == "uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice"
      result[:content_length].should == "0"

    end

    context "single line String as response data" do
      before { @data = ROOT_DEVICE1.gsub("\n", " ") }

      it "returns an empty Hash" do
        subject.parse(@data).should == { }
      end

      it "logs the 'bad' response" do
        SSDP.should_receive(:log).twice
        subject.parse @data
      end
    end
  end

  describe "#setup_multicast_socket" do
    it "adds 0.0.0.0 and 239.255.255.250 to the membership group" do
      subject.should_receive(:set_membership).with(
        IPAddr.new('239.255.255.250').hton + IPAddr.new('0.0.0.0').hton
      )
      subject.setup_multicast_socket
    end

    it "sets multicast TTL to 4" do
      subject.should_receive(:set_multicast_ttl).with(4)
      subject.setup_multicast_socket
    end

    it "sets TTL to 4" do
      subject.should_receive(:set_ttl).with(4)
      subject.setup_multicast_socket
    end

    context "ENV['RUBY_UPNP_ENV'] != testing" do
      after { ENV['RUBY_UPNP_ENV'] = "testing" }

      it "turns multicast loop off" do
        ENV['RUBY_UPNP_ENV'] = "development"
        subject.should_receive(:switch_multicast_loop).with(:off)
        subject.setup_multicast_socket
      end
    end
  end

  describe "#switch_multicast_loop" do
    it "passes '\\001' to the socket option call when param == :on" do
      subject.should_receive(:set_sock_opt).with(
        0, 11, "\001"
      )
      subject.switch_multicast_loop :on
    end

    it "passes '\\001' to the socket option call when param == '\\001'" do
      subject.should_receive(:set_sock_opt).with(
        0, 11, "\001"
      )
      subject.switch_multicast_loop "\001"
    end

    it "passes '\\000' to the socket option call when param == :off" do
      subject.should_receive(:set_sock_opt).with(
        0, 11, "\000"
      )
      subject.switch_multicast_loop :off
    end

    it "passes '\\000' to the socket option call when param == '\\000'" do
      subject.should_receive(:set_sock_opt).with(
        0, 11, "\000"
      )
      subject.switch_multicast_loop "\000"
    end

    it "raises when not :on, :off, '\\000', or '\\001'" do
      expect { subject.switch_multicast_loop 12312312 }.to raise_exception(
        SSDP::Error
      )
    end
  end
end

