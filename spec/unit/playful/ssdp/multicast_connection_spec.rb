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
      allow_any_instance_of(Playful::SSDP::MulticastConnection).to receive(:setup_multicast_socket)
      subject.stub_chain(:get_peername, :[], :unpack).
          and_return(%w[1234 1 2 3 4])
    end

    it 'returns an Array with IP and port' do
      expect(subject.peer_info).to eq ['1.2.3.4', 1234]
    end

    it 'returns IP as a String' do
      expect(subject.peer_info.first).to be_a String
    end

    it 'returns port as a Fixnum' do
      expect(subject.peer_info.last).to be_a Fixnum
    end
  end

  describe '#parse' do
    before do
      allow_any_instance_of(Playful::SSDP::MulticastConnection).to receive(:setup_multicast_socket)
    end

    it 'turns headers into Hash keys' do
      result = subject.parse ROOT_DEVICE1
      expect(result).to have_key :cache_control
      expect(result).to have_key :date
      expect(result).to have_key :location
      expect(result).to have_key :server
      expect(result).to have_key :st
      expect(result).to have_key :ext
      expect(result).to have_key :usn
      expect(result).to have_key :content_length
    end

    it 'turns header values into Hash values' do
      result = subject.parse ROOT_DEVICE1
      expect(result[:cache_control]).to eq 'max-age=1200'
      expect(result[:date]).to eq 'Mon, 26 Sep 2011 06:40:19 GMT'
      expect(result[:location]).to eq 'http://1.2.3.4:5678/description/fetch'
      expect(result[:server]).to eq 'Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1'
      expect(result[:st]).to eq 'upnp:rootdevice'
      expect(result[:ext]).to be_empty
      expect(result[:usn]).to eq 'uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice'
      expect(result[:content_length]).to eq '0'
    end

    context 'single line String as response data' do
      before { @data = ROOT_DEVICE1.gsub("\n", ' ') }

      it 'returns an empty Hash' do
        expect(subject.parse(@data)).to eq({ })
      end

      it "logs the 'bad' response" do
        subject.should_receive(:log).twice
        subject.parse @data
      end
    end
  end

  describe '#setup_multicast_socket' do
    before do
      allow_any_instance_of(Playful::SSDP::MulticastConnection).to receive(:set_membership)
      allow_any_instance_of(Playful::SSDP::MulticastConnection).to receive(:switch_multicast_loop)
      allow_any_instance_of(Playful::SSDP::MulticastConnection).to receive(:set_multicast_ttl)
      allow_any_instance_of(Playful::SSDP::MulticastConnection).to receive(:set_ttl)
    end

    it 'adds 0.0.0.0 and 239.255.255.250 to the membership group' do
      expect(subject).to receive(:set_membership).with(
        IPAddr.new('239.255.255.250').hton + IPAddr.new('0.0.0.0').hton
      )
      subject.setup_multicast_socket
    end

    it 'sets multicast TTL to 4' do
      expect(subject).to receive(:set_multicast_ttl).with(4)
      subject.setup_multicast_socket
    end

    it 'sets TTL to 4' do
      expect(subject).to receive(:set_ttl).with(4)
      subject.setup_multicast_socket
    end

    context "ENV['RUBY_UPNP_ENV'] != testing" do
      after { ENV['RUBY_UPNP_ENV'] = 'testing' }

      it 'turns multicast loop off' do
        ENV['RUBY_UPNP_ENV'] = 'development'
        expect(subject).to receive(:switch_multicast_loop).with(:off)
        subject.setup_multicast_socket
      end
    end
  end

  describe '#switch_multicast_loop' do
    before do
      allow_any_instance_of(Playful::SSDP::MulticastConnection).to receive(:setup_multicast_socket)
    end

    it "passes '\\001' to the socket option call when param == :on" do
      expect(subject).to receive(:set_sock_opt).with(
        Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\001"
      )
      subject.switch_multicast_loop :on
    end

    it "passes '\\001' to the socket option call when param == '\\001'" do
      expect(subject).to receive(:set_sock_opt).with(
       Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\001"
      )
      subject.switch_multicast_loop "\001"
    end

    it "passes '\\000' to the socket option call when param == :off" do
      expect(subject).to receive(:set_sock_opt).with(
        Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, "\000"
      )
      subject.switch_multicast_loop :off
    end

    it "passes '\\000' to the socket option call when param == '\\000'" do
      expect(subject).to receive(:set_sock_opt).with(
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

