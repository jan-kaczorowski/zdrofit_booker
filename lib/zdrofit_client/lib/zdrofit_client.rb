require "httparty"
require "socksify"
require "zdrofit_client/version"
require_relative "zdrofit_client/api_call"

module ZdrofitClient
  class Error < StandardError; end

  module ApiCalls
  end

  def self.new(login, password)
    Client.new(login, password)
  end

  def self.configure_proxy(url)
    return if url.nil? || url.empty?

    uri = URI.parse(url)
    TCPSocket.socks_server = uri.host
    TCPSocket.socks_port = uri.port
    TCPSocket.socks_username = uri.user if uri.user
    TCPSocket.socks_password = uri.password if uri.password
  end

  def self.disable_proxy
    TCPSocket.socks_server = nil
    TCPSocket.socks_port = nil
    TCPSocket.socks_username = nil
    TCPSocket.socks_password = nil
  end
end

# Load all API calls
Dir[File.join(__dir__, "zdrofit_client/api_calls", "*.rb")].each do |file|
  require_relative file
end

require_relative "zdrofit_client/client"
