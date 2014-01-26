require 'spec_helper'
require 'playful/ssdp/listener'


describe Playful::SSDP::Listener do
  around(:each) do |example|
    EM.synchrony do
      example.run
      EM.stop
    end
  end

  before do
    Playful::SSDP::Listener.any_instance.stub(:setup_multicast_socket)
  end

  subject { Playful::SSDP::Listener.new(1) }

  describe '#receive_data' do
    it 'logs the IP and port from which the request came from' do
      subject.should_receive(:peer_info).and_return ['ip', 'port']
      subject.should_receive(:log).
        with("Response from ip:port:\nmessage\n")
      subject.stub(:parse).and_return {}

      subject.receive_data('message')
    end
  end
end