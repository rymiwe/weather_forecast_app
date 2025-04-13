# frozen_string_literal: true

# Configure weather application settings
Rails.application.configure do
  # Define weather-related configuration under the 'x' namespace
  config.x.weather = ActiveSupport::InheritableOptions.new
  
  # Default unit for temperature display (metric or imperial)
  config.x.weather.default_unit = 'metric'
  
  # Cache duration for weather data (in seconds)
  # Set from environment variable or use default (30 minutes)
  config.x.weather.cache_ttl = ENV.fetch('WEATHER_CACHE_TTL', 30.minutes)
  
  # Use mock weather data in development only if no API key is provided
  if Rails.env.development?
    api_key = ENV['WEATHERAPI_KEY']
    config.x.weather.use_mock_client = api_key.nil? || api_key.empty?
    Rails.logger.info "Weather client setting: #{config.x.weather.use_mock_client ? 'Using MOCK client' : 'Using REAL client'}"
  end
  
  # Whether to use mock weather data in test
  # Use real client if API key is provided, otherwise use mock client
  config.x.weather.use_mock_client = Rails.env.test? if Rails.env.test?
end
