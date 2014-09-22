require 'rspec'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'leda'

Dir[File.expand_path('../support/*.rb', __FILE__)].each do |support|
  require support
end

RSpec.configure do |config|
  config.include Leda::Spec::Tmpdir

  config.after { rm_tmpdir }
end
