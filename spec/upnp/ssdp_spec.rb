require_relative '../spec_helper'

describe SSDP do
  describe '.listen' do
    context 'sets up a multicast socket' do
      it 'with IP_MULTICAST_LOOP set to 11' do
        begin
          Thread.new { SSDP.listen }
          sleep 5
          Socket::IP_MULTICAST_LOOP.should == 11
        ensure
          EM.stop if EM.reactor_running?
        end
      end

      it 'by setting IP_MULTICAST_TTL to 10' do
        begin
          Thread.new { SSDP.listen }
          Socket::IP_MULTICAST_TTL.should == 10
        ensure
          EM.stop if EM.reactor_running?
        end
      end

      it 'by setting IP_TTL to 4' do
        begin
          Thread.new { SSDP.listen }
          Socket::IP_TTL.should == 4
        ensure
          EM.stop if EM.reactor_running?
        end
      end
    end
  end
end
