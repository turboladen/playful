require 'spec_helper'
require 'playful/ssdp/notifier'


describe Playful::SSDP::Notifier do
  around(:each) do |example|
    EM.synchrony do
      example.run
      EM.stop
    end
  end

  let(:nt) { 'en tee' }
  let(:usn) { 'you ess en' }
  let(:ddf_url) { 'ddf url' }
  let(:duration) { 567 }

  subject do
    Playful::SSDP::Notifier.new(1, nt, usn, ddf_url, duration)
  end

  describe '#initialize' do
    it 'creates a notification' do
      Playful::SSDP::Notifier.any_instance.should_receive(:notification).
        with(nt, usn, ddf_url, duration)

      subject
    end
  end

  describe '#post_init' do
    context 'send_datagram returns positive value' do
      before do
        subject.should_receive(:send_datagram).and_return 1
      end

      it 'logs what was sent' do
        subject.should_receive(:log).with /Sent notification/

        subject.post_init
      end
    end

    context 'send_datagram returns 0' do
      before do
        subject.should_receive(:send_datagram).and_return 0
      end

      it 'does not log what was sent' do
        subject.should_not_receive(:log)

        subject.post_init
      end
    end
  end

  describe '#notification' do
    before do
      subject.instance_variable_set(:@os, 'my OS')
    end

    it 'builds the notification message' do
      subject.notification(nt, usn, ddf_url, duration).should == <<-NOTE
NOTIFY * HTTP/1.1\r
HOST: 239.255.255.250:1900\r
CACHE-CONTROL: max-age=567\r
LOCATION: ddf url\r
NT: en tee\r
NTS: ssdp:alive\r
SERVER: my OS UPnP/1.0 RubySSDP/0.1.0\r
USN: you ess en\r
\r
      NOTE
    end
  end
end