# frozen_string_literal: true

require 'json'
require_relative 'api_client_base'

# Client for interacting with the WeatherAPI.com service
# Provides simplified single-call weather data with automatic location resolution
class WeatherApiClient < ApiClientBase
  API_BASE_URL = 'https://api.weatherapi.com'.freeze
  FORECAST_DAYS = 7
  DEFAULT_CACHE_TTL = 30.minutes

  # Initialize with the API key from environment
  def initialize
    @api_key = ENV['WEATHERAPI_KEY']
    @use_mock = use_mock_client?
    @weather_cache_ttl = Rails.configuration.x.weather.cache_ttl || DEFAULT_CACHE_TTL

    log_initialization

    super(api_key: @api_key, base_url: API_BASE_URL)
  end

  # Get weather data for a given lat,lon string in a single API call
  # @param address [String] The lat,lon string to get weather for
  # @return [Hash] Weather data including current and forecast
  def get_weather(address:)
    Rails.logger.info "WeatherApiClient: Getting weather for coordinates: #{address}"

    return nil if missing_api_key_in_production?
    return mock_weather(address) if @use_mock

    fetch_or_cache_weather(address)
  end

  # Class method for spec compatibility
  def self.fetch_forecast(address)
    data = instance.get_weather(address: address)
    data.deep_stringify_keys
  end

  private

  def use_mock_client?
    Rails.configuration.x.weather.use_mock_client || 
      ENV['USE_MOCK_WEATHER_CLIENT'] == 'true'
  end

  def log_initialization
    Rails.logger.debug "WeatherApiClient initialized with mock: #{@use_mock}, " \
                       "cache TTL: #{@weather_cache_ttl}, API key present: #{@api_key.present?}"
  end

  def missing_api_key_in_production?
    if Rails.env.production? && @api_key.blank?
      Rails.logger.error "WeatherApiClient: Cannot fetch weather in production without API key"
      return true
    end
    false
  end

  def mock_weather(address)
    Rails.logger.info "WeatherApiClient: Returning sample forecast data for #{address}"
    Forecast.sample_forecast_data
  end

  def fetch_or_cache_weather(address)
    cache_key = "weather:#{address}"

    Rails.cache.fetch(cache_key, expires_in: @weather_cache_ttl) do
      Rails.logger.info "WeatherApiClient: Cache miss, fetching from API for #{address}"
      fetch_from_api(address)
    end
  end

  def fetch_from_api(address)
    begin
      response = real_get_weather(address)
    rescue StandardError => e
      Rails.logger.error "WeatherApiClient: Error fetching weather for #{address}: #{e.message}"
      return nil
    end

    Rails.logger.info "WeatherApiClient: API response: #{response ? 'Success' : 'Nil'}"

    if response.nil?
      Rails.logger.warn "WeatherApiClient: No response from API for #{address}"
      return nil
    end

    transform_response(response)
  end

  def real_get_weather(address)
    Rails.logger.info "WeatherApiClient#real_get_weather: Starting API request for #{address}"

    # address is now always a lat,lon string
    query = address
    endpoint = "/v1/forecast.json"
    params = {
      q: query,
      days: FORECAST_DAYS,
      aqi: 'yes',
      key: @api_key
    }

    headers = { 'User-Agent' => 'WeatherForecastApp/1.0' }

    request(endpoint, params, headers)
  end

  # Transform WeatherAPI response to match our application's expected structure
  # @param data [Hash] The raw API response
  # @return [Hash] Transformed data structure
  def transform_response(data)
    return nil unless data && data[:location] && data[:current] && data[:forecast]

    # Extract relevant data in a format that matches our application's expectations
    {
      current: {
        'name' => data[:location][:name],
        'region' => data[:location][:region],
        'country' => data[:location][:country],
        'lat' => data[:location][:lat],
        'lon' => data[:location][:lon],
        'temp_c' => data[:current][:temp_c],
        'temp_f' => data[:current][:temp_f],
        'condition' => {
          'text' => data[:current][:condition][:text],
          'icon' => data[:current][:condition][:icon],
          'code' => data[:current][:condition][:code]
        },
        'wind_kph' => data[:current][:wind_kph],
        'wind_mph' => data[:current][:wind_mph],
        'wind_dir' => data[:current][:wind_dir],
        'humidity' => data[:current][:humidity],
        'cloud' => data[:current][:cloud],
        'feelslike_c' => data[:current][:feelslike_c],
        'feelslike_f' => data[:current][:feelslike_f],
        'vis_km' => data[:current][:vis_km],
        'vis_miles' => data[:current][:vis_miles],
        'uv' => data[:current][:uv],
        'gust_mph' => data[:current][:gust_mph],
        'gust_kph' => data[:current][:gust_kph]
      },
      forecast: data[:forecast],
      location: data[:location]
    }
  end

  # Get weather cache TTL from configuration
  # @return [Integer] Cache TTL in seconds
  def weather_cache_ttl
    @weather_cache_ttl
  end
end
