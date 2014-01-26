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
    allow_any_instance_of(Playful::SSDP::Listener).to receive(:setup_multicast_socket)
  end

  subject { Playful::SSDP::Listener.new(1) }

  describe '#receive_data' do
    it 'logs the IP and port from which the request came from' do
      expect(subject).to receive(:peer_info).and_return ['ip', 'port']
      expect(subject).to receive(:log).
        with("Response from ip:port:\nmessage\n")
      allow(subject).to receive(:parse).and_return({})

      subject.receive_data('message')
    end
  end
end