require './lib/upnp/control_point'
require 'pry'

UPnP::SSDP.log = false

#search_for ="ssdp:all"
search_for ="upnp:rootdevice"
#search_for = "uuid:100330fe-5d3e-4a5e-98c7-0000a6504b8c-Camera-5::urn:schemas-pelco-com:service:VideoOutput:1"
#search_for = "uuid:100330fe-5d3e-4a5e-98c7-0000a6504b8c-Camera-2"

cp = UPnP::ControlPoint.new(search_for)
cp.start

binding.pry


=begin
require 'savon'

Savon.configure do |c|
  c.env_namespace = :s
end

wsdl_namespace = "urn:schemas-upnp-org:service:ContentDirectory:1"

# create a client for your SOAP service
client = Savon.client do
  wsdl.endpoint = "http://192.168.10.3:5001/upnp/control/content_directory"
  wsdl.namespace = wsdl_namespace
end

action_name = "GetSearchCapabilities"

# execute a SOAP request to call the "getUser" action
response = client.request(:u, action_name, "xmlns:u" => wsdl_namespace) do
#response = client.request(:u, %Q{#{action_name}}) do
  http.headers['SOAPACTION'] = %Q{"#{wsdl_namespace}##{action_name}"}
  soap.body = {
    :argument_name => "ConnectionID"
  }
end

p response
=end
