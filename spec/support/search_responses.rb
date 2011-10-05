
ROOT_DEVICE1 = <<-RD
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=1200
DATE: Mon, 26 Sep 2011 06:40:19 GMT
LOCATION: http://192.168.10.3:5001/description/fetch
SERVER: Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1
ST: upnp:rootdevice
EXT:
USN: uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice
Content-Length: 0

RD

ROOT_DEVICE2 = <<-RD
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=1200
DATE: Mon, 26 Sep 2011 06:40:20 GMT
LOCATION: http://192.168.10.4:5001/description/fetch
SERVER: Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1
ST: upnp:rootdevice
EXT:
USN: uuid:3c202906-992d-3f0f-b94c-90e1902a136e::upnp:rootdevice
Content-Length: 0

RD

MEDIA_SERVER = <<-MD
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=1200
DATE: Mon, 26 Sep 2011 06:40:21 GMT
LOCATION: http://192.168.10.3:5001/description/fetch
SERVER: Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1
ST: urn:schemas-upnp-org:device:MediaServer:1
EXT:
USN: uuid:3c202906-992d-3f0f-b94c-90e1902a136d::urn:schemas-upnp-org:device:MediaServer:1
Content-Length: 0

MD

RESPONSES = {
  root_device1: ROOT_DEVICE1,
  root_device2: ROOT_DEVICE2,
  media_server: MEDIA_SERVER
}

SSDP_SEARCH_RESPONSES_PARSED = {
  root_device1: {
    cache_control: "max-age=1200",
    date: "Mon, 26 Sep 2011 06:40:19 GMT",
    location: "http://192.168.10.3:5001/description/fetch",
    server: "Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1",
    st: "upnp:rootdevice",
    ext: nil,
    usn: "uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice",
    content_length: 0
  },
  root_device2: {
    cache_control: "max-age=1200",
    date: "Mon, 26 Sep 2011 06:40:20 GMT",
    location: "http://192.168.10.4:5001/description/fetch",
    server: "Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1",
    st: "upnp:rootdevice",
    ext: nil,
    usn: "uuid:3c202906-992d-3f0f-b94c-90e1902a136e::upnp:rootdevice",
    content_length: 0
  },
  media_server: {
    cache_control: "max-age=1200",
    date: "Mon, 26 Sep 2011 06:40:21 GMT",
    location: "http://192.168.10.3:5001/description/fetch",
    server: "Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1",
    st: "urn:schemas-upnp-org:device:MediaServer:1",
    ext: nil,
    usn: "uuid:3c202906-992d-3f0f-b94c-90e1902a136d::urn:schemas-upnp-org:device:MediaServer:1",
    content_length: 0
  }
}
