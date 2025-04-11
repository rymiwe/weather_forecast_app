require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter out sensitive data like API keys
  config.filter_sensitive_data('<OPENWEATHERMAP_API_KEY>') { ENV['OPENWEATHERMAP_API_KEY'] }
  
  # Allow localhost connections for browser tests
  config.ignore_localhost = true
  
  # Configure VCR to work with RSpec
  config.configure_rspec_metadata!
  
  # Record new HTTP interactions if none exist yet
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri]
  }
end

# Ensure we have the directory for cassettes
FileUtils.mkdir_p 'spec/vcr_cassettes'
