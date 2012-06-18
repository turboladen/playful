require 'test/unit'
require 'test/utilities'
require 'SSDP'

class TestSSDPResponse < SSDP::TestCase

  def setup
    super

    @response = SSDP::Response.parse util_search_response
  end

  def test_self_parse_notify
    assert_equal Time, @response.date.class
    assert_equal true, @response.ext
    assert_equal URI.parse('http://example.com/root_device.xml'),
                 @response.location
    assert_equal 10, @response.max_age
    assert_equal 'uuid:BOGUS::upnp:rootdevice', @response.name
    assert_equal 'OS/5 UPnP/1.0 product/7', @response.server
    assert_equal 'upnp:rootdevice', @response.target
  end

  def test_inspect
    id = @response.object_id.to_s 16
    expected = "#<SSDP::Response:0x#{id} upnp:rootdevice http://example.com/root_device.xml>"

    assert_equal expected, @response.inspect
  end

end
