require_relative '../logger'
require_relative 'multicast_connection'


class Playful::SSDP::Notifier < Playful::SSDP::MulticastConnection
  include LogSwitch::Mixin

  def initialize(nt, usn, ddf_url, valid_for_duration)
    @os = RbConfig::CONFIG['host_vendor'].capitalize + '/' +
      RbConfig::CONFIG['host_os']
    @upnp_version = '1.0'
    @notification = notification(nt, usn, ddf_url, valid_for_duration)
  end

  def post_init
    if send_datagram(@notification, MULTICAST_IP, MULTICAST_PORT) > 0
      log "Sent notification:\n#{@notification}"
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
HOST: #{MULTICAST_IP}:#{MULTICAST_PORT}\r
CACHE-CONTROL: max-age=#{valid_for_duration}\r
LOCATION: #{ddf_url}\r
NT: #{nt}\r
NTS: ssdp:alive\r
SERVER: #{@os} Playful/#{@upnp_version} RubySSDP/#{Playful::VERSION}\r
USN: #{usn}\r
\r
    NOTIFICATION
  end
end
