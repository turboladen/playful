require 'spec_helper'
require 'upnp/ssdp'


describe UPnP::SSDP do
  subject { UPnP::SSDP }

  describe '.listen' do
    let(:listener) do
      searcher = double 'UPnP::SSDP::Listener'
      searcher.stub_chain(:alive_notifications, :pop).and_yield(%w[one two])
      searcher.stub_chain(:byebye_notifications, :pop).and_yield(%w[three four])

      searcher
    end

    before do
      EM.stub(:run).and_yield
      EM.stub(:add_timer)
      EM.stub(:open_datagram_socket).and_return listener
    end

    context 'reactor is already running' do
      it 'returns a UPnP::SSDP::Listener' do
        EM.stub(:reactor_running?).and_return true
        subject.listen.should == listener
      end
    end

    context 'reactor is not already running' do
      it 'returns a Hash of available and byebye responses' do
        EM.stub(:add_shutdown_hook).and_yield
        subject.listen.should == {
          alive_notifications: %w[one two],
          byebye_notifications: %w[three four]
        }
      end

      it 'opens a UDP socket on 239.255.255.250, port 1900' do
        EM.stub(:add_shutdown_hook)
        EM.should_receive(:open_datagram_socket).with('239.255.255.250', 1900,
          UPnP::SSDP::Listener, 4)
        subject.listen
      end
    end
  end

  describe '.search' do
    let(:multicast_searcher) do
      searcher = double 'UPnP::SSDP::Searcher'
      searcher.stub_chain(:discovery_responses, :subscribe).and_yield(%w[one two])

      searcher
    end

    let(:broadcast_searcher) do
      searcher = double 'UPnP::SSDP::BroadcastSearcher'
      searcher.stub_chain(:discovery_responses, :subscribe).and_yield(%w[three four])

      searcher
    end

    before do
      EM.stub(:run).and_yield
      EM.stub(:add_timer)
      EM.stub(:open_datagram_socket).and_return multicast_searcher
    end

    context 'when search_target is not a String' do
      it 'calls #to_upnp_s on search_target' do
        search_target = double('search_target')
        search_target.should_receive(:to_upnp_s)
        subject.search(search_target)
      end
    end

    context 'when search_target is a String' do
      it 'calls #to_upnp_s on search_target but does not alter it' do
        search_target = "I'm a string"
        search_target.should_receive(:to_upnp_s).and_call_original

        EM.should_receive(:open_datagram_socket).with('0.0.0.0', 0,
          UPnP::SSDP::Searcher, "I'm a string", {})
        subject.search(search_target)
      end
    end

    context 'reactor is already running' do
      it 'returns a UPnP::SSDP::Searcher' do
        EM.stub(:reactor_running?).and_return true
        subject.search.should == multicast_searcher
      end
    end

    context 'reactor is not already running' do
      context 'options hash includes do_broadcast_search' do
        before do
          EM.stub(:open_datagram_socket).
            and_return(multicast_searcher, broadcast_searcher)
        end

        it 'returns an Array of responses' do
          EM.stub(:add_shutdown_hook).and_yield
          subject.search(:all, do_broadcast_search: true).should == %w[one two three four]
        end

        it 'opens 2 UDP sockets on 0.0.0.0, port 0' do
          EM.stub(:add_shutdown_hook)
          EM.should_receive(:open_datagram_socket).with('0.0.0.0', 0, UPnP::SSDP::Searcher,
            'ssdp:all', {})
          EM.should_receive(:open_datagram_socket).with('0.0.0.0', 0, UPnP::SSDP::BroadcastSearcher,
            'ssdp:all', 5, 4)
          subject.search(:all, do_broadcast_search: true)
        end
      end

      context 'options hash does not include do_broadcast_search' do
        it 'returns an Array of responses' do
          EM.stub(:add_shutdown_hook).and_yield
          subject.search.should == %w[one two]
        end

        it 'opens a UDP socket on 0.0.0.0, port 0' do
          EM.stub(:add_shutdown_hook)
          EM.should_receive(:open_datagram_socket).with('0.0.0.0', 0, UPnP::SSDP::Searcher,
            'ssdp:all', {})
          subject.search
        end
      end
    end
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

