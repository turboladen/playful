require 'spec_helper'
require 'playful/control_point'


describe Playful::ControlPoint do
  subject do
    Playful::ControlPoint.new(1)
  end

  describe '#ssdp_search_and_listen' do
    let(:notification) do
      double 'notification'
    end

    let(:searcher) do
      s = double 'Playful::SSDP::Searcher'
      s.stub_chain(:discovery_responses, :subscribe).and_yield notification

      s
    end

    before do
      expect(Playful::SSDP).to receive(:search).with('ssdp:all', {}).and_return searcher
      EM.stub(:add_periodic_timer)
    end

    after do
      EM.unstub(:add_periodic_timer)
    end

    it 'creates a ControlPoint::Device for every discovery response' do
      EM.stub(:add_timer)
      subject.should_receive(:create_device).with(notification)
      subject.ssdp_search_and_listen('ssdp:all')
    end

    it 'shuts down the searcher and starts the listener after the given response wait time' do
      EM.stub(:add_timer).and_yield
      subject.stub(:create_device)
      searcher.should_receive(:close_connection)
      subject.should_receive(:listen)
      subject.ssdp_search_and_listen('ssdp:all')
    end
  end
end
