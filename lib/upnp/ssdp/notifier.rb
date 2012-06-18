require_relative 'connection'
require_relative 'version'

class SSDP::Notifier < SSDP::Connection

  def initialize(nt, usn, ddf_url, valid_for_duration)
    @os = RbConfig::CONFIG['host_vendor'].capitalize + "/" +
      RbConfig::CONFIG['host_os']
    @upnp_version = "1.0"
    @notification = notification(nt, usn, ddf_url, valid_for_duration)
  end

  def post_init
    if send_datagram(@notification, BROADCAST, MULTICAST_PORT) > 0
      SSDP.log("Sent notification:\n#{@notification}")
    end
  end

  # @param [String] nt "Notification Type"; a potential search target.  Used in
  #   +NT+ header.
  # @param [String] usn "Unique Service Name"; a composite identifier for the
  #   advertisement.  Used in +USN+ header.
  # @param [String] ddf_url Device Description File URL for the root device.
  # @param [Fixnum] valid_for_duration Duration in seconds for which the
  #   advertisement is valid.  Used in +CACHE-CONTROL+ header.
  def notification(nt, usn, ddf_url, valid_for_duration)
    <<-NOTIFICATION
NOTIFY * HTTP/1.1\r
HOST: #{BROADCAST}:#{MULTICAST_PORT}\r
CACHE-CONTROL: max-age=#{valid_for_duration}\r
LOCATION: #{ddf_url}\r
NT: #{nt}\r
NTS: ssdp:alive\r
SERVER: #{@os} UPnP/#{@upnp_version} RubySSDP/#{SSDP::VERSION}\r
USN: #{usn}\r
\r
    NOTIFICATION
  end
end
