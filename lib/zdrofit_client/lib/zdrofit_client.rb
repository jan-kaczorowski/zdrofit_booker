require "httparty"
require "zdrofit_client/version"
require_relative "zdrofit_client/api_call"

module ZdrofitClient
  class Error < StandardError; end

  module ApiCalls
  end

  def self.new(login, password)
    Client.new(login, password)
  end
end

# Load all API calls
Dir[File.join(__dir__, "zdrofit_client/api_calls", "*.rb")].each do |file|
  require_relative file
end

require_relative "zdrofit_client/client"
