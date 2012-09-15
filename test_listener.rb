require './lib/upnp/ssdp'

UPnP::SSDP.log = false

UPnP::SSDP.listen do |responses|
    puts "testsers got responses: #{responses}"
    exit unless responses.empty?
end
