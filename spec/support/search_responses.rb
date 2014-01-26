SSDP_SEARCH_RESPONSES_PARSED = {
  root_device1: {
    cache_control: 'max-age=1200',
    date: 'Mon, 26 Sep 2011 06:40:19 GMT',
    location: 'http://192.168.10.3:5001/description/fetch',
    server: 'Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1',
    st: 'upnp:rootdevice',
    ext: nil,
    usn: 'uuid:3c202906-992d-3f0f-b94c-90e1902a136d::upnp:rootdevice',
    content_length: 0
  },
  root_device2: {
    cache_control: 'max-age=1200',
    date: 'Mon, 26 Sep 2011 06:40:20 GMT',
    location: 'http://192.168.10.4:5001/description/fetch',
    server: 'Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1',
    st: 'upnp:rootdevice',
    ext: nil,
    usn: 'uuid:3c202906-992d-3f0f-b94c-90e1902a136e::upnp:rootdevice',
    content_length: 0
  },
  media_server: {
    cache_control: 'max-age=1200',
    date: 'Mon, 26 Sep 2011 06:40:21 GMT',
    location: 'http://192.168.10.3:5001/description/fetch',
    server: 'Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1',
    st: 'urn:schemas-upnp-org:device:MediaServer:1',
    ext: nil,
    usn: 'uuid:3c202906-992d-3f0f-b94c-90e1902a136d::urn:schemas-upnp-org:device:MediaServer:1',
    content_length: 0
  }
}

SSDP_DESCRIPTIONS = {
  root_device1: {
    'root' => {
      'specVersion' => {
        'major' => '1',
        'minor' => '0'
      },
      'URLBase' => 'http://192.168.10.3:5001/',
      'device' => {
        'dlna:X_DLNADOC' => %w[DMS-1.50 M-DMS-1.50],
        'deviceType' => 'urn:schemas-upnp-org:device:MediaServer:1',
        'friendlyName' => 'PS3 Media Server [gutenberg]',
        'manufacturer' => 'PMS',
        'manufacturerURL' => 'http://ps3mediaserver.blogspot.com',
        'modelDescription' => 'UPnP/AV 1.0 Compliant Media Server',
        'modelName' => 'PMS',
        'modelNumber' => '01',
        'modelURL' => 'http://ps3mediaserver.blogspot.com',
        'serialNumber' => nil,
        'UPC' => nil,
        'UDN' => 'uuid:3c202906-992d-3f0f-b94c-90e1902a136d',
        'iconList' => {
          'icon' => {
            'mimetype' => 'image/jpeg',
            'width' => '120',
            'height' => '120',
            'depth' => '24',
            'url' => '/images/icon-256.png'
          }
        },
        'presentationURL' => 'http://192.168.10.3:5001/console/index.html',
        'serviceList' => {
          'service' => [
            {
              'serviceType' => 'urn:schemas-upnp-org:service:ContentDirectory:1',
              'serviceId' => 'urn:upnp-org:serviceId:ContentDirectory',
              'SCPDURL' => '/UPnP_AV_ContentDirectory_1.0.xml',
              'controlURL' => '/upnp/control/content_directory',
              'eventSubURL' => '/upnp/event/content_directory'
            },
              {
                'serviceType' => 'urn:schemas-upnp-org:service:ConnectionManager:1',
                'serviceId' => 'urn:upnp-org:serviceId:ConnectionManager',
                'SCPDURL' => '/UPnP_AV_ConnectionManager_1.0.xml',
                'controlURL' => '/upnp/control/connection_manager',
                'eventSubURL' => '/upnp/event/connection_manager'
              }
          ]
        }
      },
      '@xmlns:dlna' => 'urn:schemas-dlna-org:device-1-0',
      '@xmlns' => 'urn:schemas-upnp-org:device-1-0'
    }
  }
}

ROOT_DEVICE1 = <<-RD
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=1200
DATE: Mon, 26 Sep 2011 06:40:19 GMT
LOCATION: http://1.2.3.4:5678/description/fetch
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
LOCATION: http://1.2.3.4:5678/description/fetch
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
LOCATION: http://1.2.3.4:5678/description/fetch
SERVER: Linux-i386-2.6.38-10-generic-pae, UPnP/1.0, PMS/1.25.1
ST: urn:schemas-upnp-org:device:MediaServer:1
EXT:
USN: uuid:3c202906-992d-3f0f-b94c-90e1902a136d::urn:schemas-upnp-org:device:MediaServer:
Content-Length: 0

MD

RESPONSES = {
  root_device1: ROOT_DEVICE1,
  root_device2: ROOT_DEVICE2,
  media_server: MEDIA_SERVER
}

