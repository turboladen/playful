# Abstract class for SSDP advertisements
# @private
class SSDP
# @private
  class Advertisement

    # Expiration time of this advertisement.rb
    def expiration
      date + max_age if date and max_age
    end

    # True if this advertisement.rb has expired
    def expired?
      Time.now > expiration if expiration
    end
  end
end
