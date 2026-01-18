require_relative '../config/environment'
require 'rspec/rails'
require 'factory_bot'
require 'support/vcr'
require 'support/factorybot'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
end
