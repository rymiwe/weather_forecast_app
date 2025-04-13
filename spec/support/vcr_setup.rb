require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter out sensitive data like API keys
  config.filter_sensitive_data('<WEATHERAPI_KEY>') { ENV['WEATHERAPI_KEY'] }
  
  # Allow localhost connections for browser tests
  config.ignore_localhost = true
  
  # Allow Chrome testing URLs needed for system tests
  config.ignore_request do |request|
    request.uri.include?('googlechromelabs.github.io') || 
    request.uri.include?('chromedriver') ||
    request.uri.include?('chrome-for-testing')
  end
  
  # Configure VCR to work with RSpec
  config.configure_rspec_metadata!
  
  # Allow real HTTP connections when no cassette is in use
  config.allow_http_connections_when_no_cassette = true
  
  # Record new HTTP interactions if none exist yet
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri]
  }
end

# Ensure we have the directory for cassettes
FileUtils.mkdir_p 'spec/vcr_cassettes'
