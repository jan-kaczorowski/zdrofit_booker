require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Don't record sensitive data
  config.filter_sensitive_data('<AUTH_TOKEN>') do |interaction|
    auth_header = interaction.request.headers['Authorization']&.first
    auth_header&.gsub('Bearer ', '') if auth_header
  end

  config.filter_sensitive_data('<EMAIL>') do |interaction|
    if interaction.request.body && interaction.request.body.include?('Login')
      JSON.parse(interaction.request.body)['Login'] rescue nil
    end
  end

  config.filter_sensitive_data('<PASSWORD>') do |interaction|
    if interaction.request.body && interaction.request.body.include?('Password')
      JSON.parse(interaction.request.body)['Password'] rescue nil
    end
  end
end
