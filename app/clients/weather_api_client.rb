# frozen_string_literal: true
require 'net/http'
require 'json'
require 'singleton'
require_relative 'api_client_base'

# Client for interacting with the WeatherAPI.com service
# Provides simplified single-call weather data with automatic location resolution
class WeatherApiClient < ApiClientBase
  include Singleton
  
  API_BASE_URL = 'https://api.weatherapi.com'.freeze
  
  # Initialize with the API key from environment
  def initialize
    @api_key = ENV['WEATHERAPI_KEY']
    
    # Check both Rails configuration and environment variable for maximum compatibility
    @use_mock = Rails.configuration.x.weather.use_mock_client || ENV['USE_MOCK_WEATHER_CLIENT'] == 'true'
    
    @weather_cache_ttl = Rails.configuration.x.weather.cache_ttl
    
    Rails.logger.debug "WeatherApiClient initialized with mock: #{@use_mock}, " \
                       "cache TTL: #{@weather_cache_ttl}, API key present: #{@api_key.present?}"
    
    super(api_key: @api_key, base_url: API_BASE_URL)
  end
  
  # Get weather data for a given address in a single API call
  # @param address [String] The address to get weather for (city, zip, coordinates, etc)
  # @return [Hash] Weather data including current and forecast
  def get_weather(address:)
    Rails.logger.info "WeatherApiClient: Getting weather for address: #{address}"
    
    # In production with no API key, return nil instead of showing mock data
    if Rails.env.production? && @api_key.blank?
      Rails.logger.error "WeatherApiClient: Cannot fetch weather in production without API key"
      return nil
    end
    
    # Fall back to mock in development/test if configured
    if @use_mock
      Rails.logger.info "WeatherApiClient: Using MockWeatherApiClient for #{address}"
      return MockWeatherApiClient.instance.get_weather(address: address)
    end
    
    # Normalize the address for consistent caching
    normalized_address = normalize_address(address)
    cache_key = "weather:#{normalized_address}"
    
    # Try to fetch from cache first
    Rails.cache.fetch(cache_key, expires_in: @weather_cache_ttl) do
      Rails.logger.info "WeatherApiClient: Cache miss, fetching from API for #{normalized_address}"
      
      # Make a single API call to get everything we need
      response = real_get_weather(address)
      
      Rails.logger.info "WeatherApiClient: API response: #{response ? 'Success' : 'Nil'}"
      
      if response.nil?
        Rails.logger.warn "WeatherApiClient: No response from API for #{address}"
        return nil
      end
      
      # Transform the response to match our app's expected structure
      transform_response(response)
    end
  end
  
  # Create a sample forecast with mock data
  def real_get_weather(address)
    Rails.logger.info "WeatherApiClient#real_get_weather: Starting API request for #{address}"
    
    # Ensure US ZIP codes are properly identified
    query = address
    if address.to_s.match?(/^\d{5}(-\d{4})?$/)
      # For US ZIP codes, append US to ensure proper geo-location
      query = "#{address},us" 
      Rails.logger.info "WeatherApiClient: US ZIP code detected, modified query to: #{query}"
    end
    
    # Build the API URL - use the proper v1 path 
    url = URI("#{@base_url}/v1/forecast.json")
    params = {
      q: query,
      days: 3, # WeatherAPI.com free plan allows up to 3 days
      aqi: 'yes', # Include air quality data
      key: @api_key # WeatherAPI.com uses 'key' parameter, not 'appid'
    }
    
    url.query = URI.encode_www_form(params)
    
    begin
      Rails.logger.info "WeatherApiClient: Making request to #{url.host} for #{address}"
      
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      
      request = Net::HTTP::Get.new(url)
      request["User-Agent"] = "WeatherForecastApp/1.0"
      
      response = https.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        Rails.logger.info "WeatherApiClient: Successful API response for #{address}"
        return JSON.parse(response.body)
      else
        Rails.logger.error "WeatherApiClient: API error: #{response.code} - #{response.body}"
        return nil
      end
    rescue StandardError => e
      Rails.logger.error "WeatherApiClient Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
      nil
    end
  end
  
  private
  
  # Normalize address for consistent caching
  # @param address [String] The address to normalize
  # @return [String] Normalized address
  def normalize_address(address)
    # Simple address normalization for stable cache keys
    if address.to_s.match?(/^\d{5}(-\d{4})?$/)
      # For US zip codes, append ",us" to ensure consistent geolocation
      return "#{address.to_s.strip},us"
    elsif match = address.to_s.match(/([a-z\s.]+),\s*([a-z]{2})/i)
      # For "City, ST" format, normalize to lowercase with standard spacing
      city, state = match[1].strip, match[2].strip
      return "#{city.downcase},#{state.downcase}"
    else
      # For other formats, just lowercase and normalize spacing
      return address.to_s.strip.downcase.gsub(/\s+/, ' ')
    end
  end
  
  # Transform WeatherAPI response to match our application's expected structure
  # @param data [Hash] The raw API response
  # @return [Hash] Transformed data structure
  def transform_response(data)
    return nil unless data && data['location'] && data['current'] && data['forecast']
    
    # Extract relevant data in a format that matches our application's expectations
    {
      current_weather: {
        'name' => data['location']['name'],
        'region' => data['location']['region'],
        'country' => data['location']['country'],
        'lat' => data['location']['lat'],
        'lon' => data['location']['lon'],
        'temp_c' => data['current']['temp_c'],
        'temp_f' => data['current']['temp_f'],
        'condition' => {
          'text' => data['current']['condition']['text'],
          'icon' => data['current']['condition']['icon'],
          'code' => data['current']['condition']['code']
        },
        'wind_kph' => data['current']['wind_kph'],
        'wind_mph' => data['current']['wind_mph'],
        'wind_dir' => data['current']['wind_dir'],
        'humidity' => data['current']['humidity'],
        'cloud' => data['current']['cloud'],
        'feelslike_c' => data['current']['feelslike_c'],
        'feelslike_f' => data['current']['feelslike_f'],
        'vis_km' => data['current']['vis_km'],
        'vis_miles' => data['current']['vis_miles'],
        'uv' => data['current']['uv'],
        'gust_mph' => data['current']['gust_mph'],
        'gust_kph' => data['current']['gust_kph']
      },
      forecast: {
        'forecastday' => data['forecast']['forecastday'].map do |day|
          {
            'date' => day['date'],
            'date_epoch' => day['date_epoch'],
            'day' => {
              'maxtemp_c' => day['day']['maxtemp_c'],
              'maxtemp_f' => day['day']['maxtemp_f'],
              'mintemp_c' => day['day']['mintemp_c'],
              'mintemp_f' => day['day']['mintemp_f'],
              'avgtemp_c' => day['day']['avgtemp_c'],
              'avgtemp_f' => day['day']['avgtemp_f'],
              'condition' => {
                'text' => day['day']['condition']['text'],
                'icon' => day['day']['condition']['icon'],
                'code' => day['day']['condition']['code']
              },
              'uv' => day['day']['uv']
            },
            'astro' => day['astro'],
            'hour' => day['hour'].map do |hour|
              {
                'time_epoch' => hour['time_epoch'],
                'time' => hour['time'],
                'temp_c' => hour['temp_c'],
                'temp_f' => hour['temp_f'],
                'condition' => {
                  'text' => hour['condition']['text'],
                  'icon' => hour['condition']['icon'],
                  'code' => hour['condition']['code']
                },
                'wind_mph' => hour['wind_mph'],
                'wind_kph' => hour['wind_kph'],
                'wind_dir' => hour['wind_dir'],
                'humidity' => hour['humidity'],
                'cloud' => hour['cloud'],
                'feelslike_c' => hour['feelslike_c'],
                'feelslike_f' => hour['feelslike_f'],
                'chance_of_rain' => hour['chance_of_rain'],
                'chance_of_snow' => hour['chance_of_snow']
              }
            end
          }
        end
      },
      location: data['location']
    }
  end
  
  # Get weather cache TTL from configuration
  # @return [Integer] Cache TTL in seconds
  def weather_cache_ttl
    @weather_cache_ttl
  end
end
