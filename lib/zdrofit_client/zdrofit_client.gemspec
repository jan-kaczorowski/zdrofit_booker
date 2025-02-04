require_relative "lib/zdrofit_client/version"

Gem::Specification.new do |spec|
  spec.name = "zdrofit_client"
  spec.version = ZdrofitClient::VERSION
  spec.authors = ["Your Name"]
  spec.summary = "Zdrofit API client"
  
  spec.files = Dir["lib/**/*", "Gemfile", "zdrofit_client.gemspec"]
  spec.require_paths = ["lib"]
  
  spec.add_dependency "httparty"
end 