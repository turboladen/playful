require 'simplecov'

SimpleCov.start

require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |file| require file }

ENV['RUBY_UPNP_ENV'] = 'testing'

RSpec.configure do |config|
  #config.raise_errors_for_deprecations!
end
