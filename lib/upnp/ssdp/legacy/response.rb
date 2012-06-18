require_relative 'advertisement'

class SSDP
  
  # Holds information about a M-SEARCH response
  class Response < Advertisement

    # Date response was created or received
    attr_reader :date

    # true if MAN header was understood
    attr_reader :ext

    # URI where this device or service is described
    attr_reader :location

    # Maximum age this advertisement.rb is valid for
    attr_reader :max_age

    # Unique Service Name
    attr_reader :name

    # Server version string
    attr_reader :server

    # Search target
    attr_reader :target

    # Creates a new Response by parsing the text in +response+
    def self.parse(response)
      response =~ /^cache-control:\s*max-age\s*=\s*(\d+)/i
      max_age = Integer $1

      response =~ /^date:\s*(.*)/i
      date = $1 ? Time.parse($1) : Time.now

      ext = !!(response =~ /^ext:/i)

      response =~ /^location:\s*(\S*)/i
      location = URI.parse $1.strip

      response =~ /^server:\s*(.*)/i
      server = $1.strip

      response =~ /^st:\s*(\S*)/i
      target = $1.strip

      response =~ /^usn:\s*(\S*)/i
      name = $1.strip

      new date, max_age, location, server, target, name, ext
    end

    # Creates a new Response
    def initialize(date, max_age, location, server, target, name, ext)
      @date = date
      @max_age = max_age
      @location = location
      @server = server
      @target = target
      @name = name
      @ext = ext
    end
  end
end
