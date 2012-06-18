require 'test/unit'
require 'test/utilities'
require 'ssdp'

class TestSSDPNotification < SSDP::TestCase

  def test_self_parse_notify
    notification = SSDP::Notification.parse util_notify

    assert_equal Time, notification.date.class
    assert_equal '239.255.255.250', notification.host
    assert_equal '1900', notification.port
    assert_equal URI.parse('http://example.com/root_device.xml'),
                 notification.location
    assert_equal 10, notification.max_age
    assert_equal 'uuid:BOGUS::upnp:rootdevice', notification.name
    assert_equal 'upnp:rootdevice', notification.type
    assert_equal 'OS/5 SSDP/1.0 product/7', notification.server
    assert_equal 'ssdp:alive', notification.sub_type
  end

  def test_self_parse_notify_byebye
    notification = SSDP::Notification.parse util_notify_byebye

    assert_equal Time, notification.date.class
    assert_equal '239.255.255.250', notification.host
    assert_equal '1900', notification.port
    assert_equal nil, notification.location
    assert_equal nil, notification.max_age
    assert_equal 'uuid:BOGUS::upnp:rootdevice', notification.name
    assert_equal 'upnp:rootdevice', notification.type
    assert_equal 'ssdp:byebye', notification.sub_type
  end

  def test_alive_eh
    notification = SSDP::Notification.parse util_notify

    assert notification.alive?

    notification = SSDP::Notification.parse util_notify_byebye

    assert !notification.alive?
  end

  def test_byebye_eh
    notification = SSDP::Notification.parse util_notify_byebye

    assert notification.byebye?

    notification = SSDP::Notification.parse util_notify

    assert !notification.byebye?
  end

  def test_inspect
    notification = SSDP::Notification.parse util_notify

    id = notification.object_id.to_s 16
    expected = "#<SSDP::Notification:0x#{id} upnp:rootdevice ssdp:alive http://example.com/root_device.xml>"

    assert_equal expected, notification.inspect
  end

  def test_inspect_byebye
    notification = SSDP::Notification.parse util_notify_byebye

    id = notification.object_id.to_s 16
    expected = "#<SSDP::Notification:0x#{id} upnp:rootdevice ssdp:byebye>"

    assert_equal expected, notification.inspect
  end

end

