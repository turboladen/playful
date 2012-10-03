require_relative 'advertisement'

# @private
class SSDP
  
  # Holds information about an M-SEARCH
  class Search < Advertisement

    attr_reader :date

    attr_reader :target

    attr_reader :wait_time

    # Creates a new Search by parsing the text in +response+
    def self.parse(response)
      response =~ /^mx:\s*(\d+)/i
      wait_time = Integer $1

      response =~ /^st:\s*(\S*)/i
      target = $1.strip

      new Time.now, target, wait_time
    end

    # Creates a new Search
    def initialize(date, target, wait_time)
      @date = date
      @target = target
      @wait_time = wait_time
    end

    # Expiration time of this advertisement.rb
    def expiration
      date + wait_time
    end
  end
end
