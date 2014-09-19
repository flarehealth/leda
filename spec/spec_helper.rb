require 'rspec'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'leda'

Dir[File.expand_path('../support/*.rb', __FILE__)].each do |support|
  require support
end

RSpec.configure do
end
