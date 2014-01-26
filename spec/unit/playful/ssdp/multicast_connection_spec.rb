require 'spec_helper'
require 'playful/ssdp/multicast_connection'


describe Playful::SSDP::MulticastConnection do
  around(:each) do |example|
    EM.synchrony do
      example.run
      EM.stop
    end
  end

  subject { Playful::SSDP::MulticastConnection.new(1) }

  before do
    Playful.log = false
  end

  describe '#peer_info' do
    before do
      Playful::SSDP::MulticastConnection.any_instance.stub(:setup_multicast_socket)
      subject.stub_chain(:get_peername, :[], :unpack).
          and_return(%w[1234 1 2 3 4])
    end

    it 'returns an Array with IP and port' do
      subject.peer_info.should == ['1.2.3.4', 1234]
    end

    it 'returns IP as a String' do
      subject.peer_info.first.should be_a String
    end

    it 'returns port as a Fixnum' do
      subject.peer_info.last.should be_a Fixnum
    end
  end

  describe '#parse' do
    before do
      Playful::SSDP::MulticastConnection.any_instance.stub(:setup_multicast_socket)
    end

    it 'turns headers into Hash keys' do
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

    it 'turns header values into Hash values' do
      result = subject.parse ROOT_DEVICE1
      result[:cache_control].should == 'max-age=1200'
      result[:date].should == 'Mon, 26 Sep 2011 06:40:19 GMT'
      result[:location].should == 'http://1.2.3.4:5678/description/fetch'
      result[:server].should == 'Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1'
      result[:st].should == 'upnp:rootdevice'
      result[:ext].should be_empty
      result[:usn].should == 'uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice'
      result[:content_length].should == '0'

    end

    context 'single line String as response data' do
      before { @data = ROOT_DEVICE1.gsub("\n", ' ') }

      it 'returns an empty Hash' do
        subject.parse(@data).should == { }
      end

      it "logs the 'bad' response" do
        subject.should_receive(:log).twice
        subject.parse @data
      end
    end
  end

  describe '#setup_multicast_socket' do
    before do
      Playful::SSDP::MulticastConnection.any_instance.stub(:set_membership)
      Playful::SSDP::MulticastConnection.any_instance.stub(:switch_multicast_loop)
      Playful::SSDP::MulticastConnection.any_instance.stub(:set_multicast_ttl)
      Playful::SSDP::MulticastConnection.any_instance.stub(:set_ttl)
    end

    it 'adds 0.0.0.0 and 239.255.255.250 to the membership group' do
      subject.should_receive(:set_membership).with(
        IPAddr.new('239.255.255.250').hton + IPAddr.new('0.0.0.0').hton
      )
      subject.setup_multicast_socket
    end

    it 'sets multicast TTL to 4' do
      subject.should_receive(:set_multicast_ttl).with(4)
      subject.setup_multicast_socket
    end

    it 'sets TTL to 4' do
      subject.should_receive(:set_ttl).with(4)
      subject.setup_multicast_socket
    end

    context "ENV['RUBY_UPNP_ENV'] != testing" do
      after { ENV['RUBY_UPNP_ENV'] = 'testing' }

      it 'turns multicast loop off' do
        ENV['RUBY_UPNP_ENV'] = 'development'
        subject.should_receive(:switch_multicast_loop).with(:off)
        subject.setup_multicast_socket
      end
    end
  end

  describe '#switch_multicast_loop' do
    before do
      Playful::SSDP::MulticastConnection.any_instance.stub(:setup_multicast_socket)
    end

    it "passes '\\001' to the socket option call when param == :on" do
      subject.should_receive(:set_sock_opt).with(
        Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\001"
      )
      subject.switch_multicast_loop :on
    end

    it "passes '\\001' to the socket option call when param == '\\001'" do
      subject.should_receive(:set_sock_opt).with(
       Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\001"
      )
      subject.switch_multicast_loop "\001"
    end

    it "passes '\\000' to the socket option call when param == :off" do
      subject.should_receive(:set_sock_opt).with(
        Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\000"
      )
      subject.switch_multicast_loop :off
    end

    it "passes '\\000' to the socket option call when param == '\\000'" do
      subject.should_receive(:set_sock_opt).with(
        Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\000"
      )
      subject.switch_multicast_loop "\000"
    end

    it "raises when not :on, :off, '\\000', or '\\001'" do
      expect { subject.switch_multicast_loop 12312312 }.
        to raise_error(Playful::SSDP::Error)
    end
  end
end

