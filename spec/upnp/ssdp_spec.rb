require_relative '../spec_helper'

describe SSDP do
  describe '.listen' do
    it 'starts the EM reactor' do
      begin
        Thread.new { SSDP.listen }
        sleep 1
        EM.reactor_running?.should be_true
      ensure
        EM.stop if EM.reactor_running?
      end
    end
  end
end
