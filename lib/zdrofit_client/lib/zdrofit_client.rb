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

  @proxy_urls = []
  @current_proxy_index = 0

  def self.configure_proxy(*urls)
    @proxy_urls = urls.flatten.compact.reject(&:empty?)
    apply_proxy(@proxy_urls.first) if @proxy_urls.any?
  end

  def self.rotate_proxy
    return if @proxy_urls.size < 2

    @current_proxy_index = (@current_proxy_index + 1) % @proxy_urls.size
    apply_proxy(@proxy_urls[@current_proxy_index])
    Rails.logger.info "[ZdrofitClient] Rotated to proxy ##{@current_proxy_index}: #{@proxy_urls[@current_proxy_index]&.gsub(/:[^:@]+@/, ':***@')}"
  end

  def self.disable_proxy
    TCPSocket.socks_server = nil
    TCPSocket.socks_port = nil
    TCPSocket.socks_username = nil
    TCPSocket.socks_password = nil
  end

  def self.apply_proxy(url)
    return disable_proxy if url.nil?

    uri = URI.parse(url)
    TCPSocket.socks_server = uri.host
    TCPSocket.socks_port = uri.port
    TCPSocket.socks_username = uri.user if uri.user
    TCPSocket.socks_password = uri.password if uri.password
  end
  private_class_method :apply_proxy
end

# Load all API calls
Dir[File.join(__dir__, "zdrofit_client/api_calls", "*.rb")].each do |file|
  require_relative file
end

require_relative "zdrofit_client/client"
