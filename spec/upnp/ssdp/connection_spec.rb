require_relative '../../spec_helper'
require 'upnp/ssdp/connection'

describe "SSDP::Connection" do
  before do
    SSDP::Connection.any_instance.stub(:set_sock_opt)
    @connection = SSDP::Connection.new(1)
  end

  it 'stuff' do
    puts "getsockopt", @connection.get_sock_opt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP)
  end
end
