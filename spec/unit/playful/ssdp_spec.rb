require 'spec_helper'
require 'playful/ssdp'


describe Playful::SSDP do
  subject { Playful::SSDP }

  describe '.listen' do
    let(:listener) do
      searcher = double 'Playful::SSDP::Listener'
      searcher.stub_chain(:alive_notifications, :pop).and_yield(%w[one two])
      searcher.stub_chain(:byebye_notifications, :pop).and_yield(%w[three four])

      searcher
    end

    before do
      allow(EM).to receive(:run).and_yield
      allow(EM).to receive(:add_timer)
      allow(EM).to receive(:open_datagram_socket).and_return listener
    end

    context 'reactor is already running' do
      it 'returns a Playful::SSDP::Listener' do
        allow(EM).to receive(:reactor_running?).and_return true
        expect(subject.listen).to eq listener
      end
    end

    context 'reactor is not already running' do
      it 'returns a Hash of available and byebye responses' do
        allow(EM).to receive(:add_shutdown_hook).and_yield
        expect(subject.listen).to eq({
          alive_notifications: %w[one two],
          byebye_notifications: %w[three four]
        })
      end

      it 'opens a UDP socket on 239.255.255.250, port 1900' do
        allow(EM).to receive(:add_shutdown_hook)
        expect(EM).to receive(:open_datagram_socket).with('239.255.255.250', 1900,
          Playful::SSDP::Listener, 4)
        subject.listen
      end
    end
  end

  describe '.search' do
    let(:multicast_searcher) do
      searcher = double 'Playful::SSDP::Searcher'
      searcher.stub_chain(:discovery_responses, :subscribe).and_yield(%w[one two])

      searcher
    end

    let(:broadcast_searcher) do
      searcher = double 'Playful::SSDP::BroadcastSearcher'
      searcher.stub_chain(:discovery_responses, :subscribe).and_yield(%w[three four])

      searcher
    end

    before do
      allow(EM).to receive(:run).and_yield
      allow(EM).to receive(:add_timer)
      allow(EM).to receive(:open_datagram_socket).and_return multicast_searcher
    end

    context 'when search_target is not a String' do
      it 'calls #to_upnp_s on search_target' do
        search_target = double('search_target')
        expect(search_target).to receive(:to_upnp_s)
        subject.search(search_target)
      end
    end

    context 'when search_target is a String' do
      it 'calls #to_upnp_s on search_target but does not alter it' do
        search_target = "I'm a string"
        expect(search_target).to receive(:to_upnp_s).and_call_original

        expect(EM).to receive(:open_datagram_socket).with('0.0.0.0', 0,
          Playful::SSDP::Searcher, "I'm a string", {})
        subject.search(search_target)
      end
    end

    context 'reactor is already running' do
      it 'returns a Playful::SSDP::Searcher' do
        allow(EM).to receive(:reactor_running?).and_return true
        expect(subject.search).to eq multicast_searcher
      end
    end

    context 'reactor is not already running' do
      context 'options hash includes do_broadcast_search' do
        before do
          allow(EM).to receive(:open_datagram_socket).
            and_return(multicast_searcher, broadcast_searcher)
        end

        it 'returns an Array of responses' do
          allow(EM).to receive(:add_shutdown_hook).and_yield
          expect(subject.search(:all, do_broadcast_search: true)).to eq %w[one two three four]
        end

        it 'opens 2 UDP sockets on 0.0.0.0, port 0' do
          allow(EM).to receive(:add_shutdown_hook)
          expect(EM).to receive(:open_datagram_socket).with('0.0.0.0', 0, Playful::SSDP::Searcher,
            'ssdp:all', {})
          expect(EM).to receive(:open_datagram_socket).with('0.0.0.0', 0, Playful::SSDP::BroadcastSearcher,
            'ssdp:all', 5, 4)
          subject.search(:all, do_broadcast_search: true)
        end
      end

      context 'options hash does not include do_broadcast_search' do
        it 'returns an Array of responses' do
          allow(EM).to receive(:add_shutdown_hook).and_yield
          expect(subject.search).to eq %w[one two]
        end

        it 'opens a UDP socket on 0.0.0.0, port 0' do
          allow(EM).to receive(:add_shutdown_hook)
          expect(EM).to receive(:open_datagram_socket).with('0.0.0.0', 0, Playful::SSDP::Searcher,
            'ssdp:all', {})
          subject.search
        end
      end
    end
  end

  describe '.notify' do
    pending 'Implementation of UPnP Devices'
  end

  describe '.send_notification' do
    pending 'Implementation of UPnP Devices'
  end

=begin
    context 'by default' do
      it "searches for 'ssdp:all'" do
        pending
      end

      it 'waits for 5 seconds for responses' do
        before = Time.now

        SSDP.search

        after = Time.now
        (after - before).should < 5.1
        (after - before).should > 5.0
      end
    end

    context "finds 'upnp:rootdevice's" do
      it "by using the spec's string 'upnp:rootdevice'" do
        SSDP.search('upnp:rootdevice').should == [
          {
            :cache_control=>'max-age=1200',
            :date=>'Mon, 26 Sep 2011 06:40:19 GMT',
            :location=>'http://192.168.10.3:5001/description/fetch',
            :server=>'Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1',
            :st=>'upnp:rootdevice',
            :ext=>'',
            :usn=>'uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice',
            :content_length=>'0'
          }
        ]
      end

      it 'by using :root' do
        pending
      end
    end

    it 'can wait for user-defined seconds for responses' do
      before = Time.now

      SSDP.search(:all, 1)

      after = Time.now
      (after - before).should < 1.1
      (after - before).should > 1.0
    end

    it 'finds a device by its URN' do
      pending
    end

    it 'finds a device by its UUID' do
      pending
    end

    it 'finds a device by its UPnP device type' do
      pending
    end

    it 'finds a device by its UPnP device type using a non-standard domain name' do
      pending
    end

    it 'finds a service by its UPnP service type' do
      pending
    end

    it 'find a service by its UPnP service type using a non-standard domain name' do
      pending
    end
=end
end

