require 'test/unit'
require 'test/utilities'
require 'ssdp'

class TestSSDPSearch < SSDP::TestCase

  def test_self_parse_search
    search = SSDP::Search.parse util_search

    assert_equal Time, search.date.class
    assert_equal 'upnp:rootdevice', search.target
    assert_equal 2, search.wait_time
  end

  def test_inspect
    search = SSDP::Search.parse util_search

    id = search.object_id.to_s 16
    expected = "#<SSDP::Search:0x#{id} upnp:rootdevice>"

    assert_equal expected, search.inspect
  end
end
