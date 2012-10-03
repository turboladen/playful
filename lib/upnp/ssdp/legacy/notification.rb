require_relative 'advertisement'

# @private
class SSDP
  
  # Holds information about a NOTIFY message.  For an alive notification, all
  # fields will be present.  For a byebye notification, location, max_age and
  # server will be nil.
  # @private
  class Notification < Advertisement

    # Date the notification was received
    attr_reader :date

    # Host the notification was sent from
    attr_reader :host

    # Port the notification was sent from
    attr_reader :port

    # Location of the advertised service or device
    attr_reader :location

    # Maximum age the advertisement.rb is valid for
    attr_reader :max_age

    # Unique Service Name of the advertisement.rb
    attr_reader :name

    # Server name and version of the advertised service or device
    attr_reader :server

    # \Notification sub-type
    attr_reader :sub_type

    # Type of the advertised service or device
    attr_reader :type

    # Parses a NOTIFY advertisement.rb into its component pieces
    def self.parse(advertisement)
      advertisement = advertisement.gsub "\r", ''

      advertisement =~ /^host:\s*(\S*)/i
      host, port = $1.split ':'

      advertisement =~ /^nt:\s*(\S*)/i
      type = $1

      advertisement =~ /^nts:\s*(\S*)/i
      sub_type = $1

      advertisement =~ /^usn:\s*(\S*)/i
      name = $1

      if sub_type == 'ssdp:alive' then
        advertisement =~ /^cache-control:\s*max-age\s*=\s*(\d+)/i
        max_age = Integer $1

        advertisement =~ /^location:\s*(\S*)/i
        location = URI.parse $1

        advertisement =~ /^server:\s*(.*)/i
        server = $1.strip
      end

      new Time.now, max_age, host, port, location, type, sub_type, server, name
    end

    # Creates a \new Notification
    def initialize(date, max_age, host, port, location, type, sub_type,
                   server, name)
      @date = date
      @max_age = max_age
      @host = host
      @port = port
      @location = location
      @type = type
      @sub_type = sub_type
      @server = server
      @name = name
    end

    # Returns true if this is a notification for a resource being alive
    def alive?
      sub_type == 'ssdp:alive'
    end

    # Returns true if this is a notification for a resource going away
    def byebye?
      sub_type == 'ssdp:byebye'
    end
  end
end
