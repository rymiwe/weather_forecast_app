# frozen_string_literal: true
require 'net/http'
require 'json'
require 'singleton'
require_relative 'api_client_base'

# Client for interacting with the OpenWeatherMap API
# Uses request-level caching with Redis for better performance
class OpenWeatherMapClient < ApiClientBase
  include Singleton
  
  API_BASE_URL = 'https://api.openweathermap.org/data/2.5'.freeze
  GEO_API_URL = 'https://api.openweathermap.org/geo/1.0'.freeze
  
  # Initialize with the API key from environment
  def initialize(api_key = ENV['OPENWEATHERMAP_API_KEY'])
    super(api_key: api_key, base_url: API_BASE_URL)
    Rails.logger.info "OpenWeatherMapClient: Initializing with API key: #{@api_key.present? ? 'Present' : 'Missing'}"
    raise ArgumentError, "OpenWeatherMap API key is required" if @api_key.blank?
  end
  
  # Get weather data for a given address
  # @param address [String] The address to get weather for
  # @return [Hash] Weather data
  def get_weather(address:)
    Rails.logger.info "OpenWeatherMapClient: Getting weather for address: #{address}"
    Rails.logger.info "OpenWeatherMapClient: API Key configured: #{ENV['OPENWEATHERMAP_API_KEY'].present? ? 'Yes' : 'No'}"
    
    coordinates = get_coordinates(address: address)
    Rails.logger.info "OpenWeatherMapClient: Coordinates lookup result: #{coordinates.inspect}"
    
    return nil unless coordinates
    
    cache_key = cache_key_for_coordinates(coordinates["lat"], coordinates["lon"])
    Rails.cache.fetch(cache_key, expires_in: weather_cache_ttl) do
      Rails.logger.info "OpenWeatherMapClient: Cache miss, fetching from API"
      
      current_weather = fetch_from_api("weather", { lat: coordinates["lat"], lon: coordinates["lon"], units: 'metric' })
      forecast = fetch_from_api("forecast", { lat: coordinates["lat"], lon: coordinates["lon"], units: 'metric' })
      
      Rails.logger.info "OpenWeatherMapClient: Current weather result: #{current_weather.inspect.truncate(100)}" if current_weather
      Rails.logger.info "OpenWeatherMapClient: Forecast result: #{forecast.inspect.truncate(100)}" if forecast
      
      return nil unless current_weather && forecast
      
      {
        current_weather: current_weather,
        forecast: forecast
      }
    end
  end
  
  private
  
  # Get coordinates for a given address
  # @param address [String] The address to get coordinates for
  # @return [Hash] The coordinates with lat and lon keys
  def get_coordinates(address:)
    # Normalize the address to avoid different formats causing duplicate cache entries
    normalized_address = normalize_string(address)
    cache_key = "geocode:#{normalized_address}"
    
    # Try to fetch from cache first
    Rails.cache.fetch(cache_key, expires_in: weather_cache_ttl) do
      # Cache miss, fetch from API
      Rails.logger.info("Geocoding address: #{normalized_address}")
      
      # Check if the address looks like a US zip code
      if normalized_address.match?(/^\d{5}(-\d{4})?$/)
        # Extract just the 5-digit part of the zip code
        zip = normalized_address.match(/^(\d{5})/)[1]
        Rails.logger.info("Using zip code API for: #{zip}")
        
        # Use the zip code endpoint instead of direct geocoding
        result = fetch_from_api("geo/1.0/zip", { zip: zip, country: "US" })
        Rails.logger.info("Zip code API result: #{result.inspect}")
        
        # Zip API returns a single result object, not an array like direct geocoding
        return result
      else
        # For non-zip addresses, use direct geocoding
        # Try to extract the city and state from a full address for better results
        query = simplified_address_for_geocoding(normalized_address)
        Rails.logger.info("Using direct geocoding API for: #{query}")
        
        result = fetch_from_api("geo/1.0/direct", { q: query, limit: 1 })
        
        if result.is_a?(Array) && result.any?
          Rails.logger.info("Direct geocoding result: #{result.first.inspect}")
          result.first
        else
          # If no results, try a more aggressive simplification
          if query != normalized_address
            Rails.logger.info("No results, trying with original address: #{normalized_address}")
            result = fetch_from_api("geo/1.0/direct", { q: normalized_address, limit: 1 })
            
            if result.is_a?(Array) && result.any?
              Rails.logger.info("Direct geocoding result with original address: #{result.first.inspect}")
              return result.first
            end
          end
          
          Rails.logger.warn("Direct geocoding returned no results for: #{query}")
          nil
        end
      end
    end
  end
  
  # Simplify an address for better geocoding results
  # @param address [String] The address to simplify
  # @return [String] Simplified address
  def simplified_address_for_geocoding(address)
    # US address with city, state format: try to extract just city and state
    if (match = address.match(/(?:.*,\s*)?([a-z\s.]+),?\s*([a-z]{2})(?:\s*\d{5}(?:-\d{4})?)?$/i))
      city, state = match[1], match[2]
      Rails.logger.info("Extracted city: #{city}, state: #{state} from address")
      return "#{city}, #{state}, US"
    end
    
    # For international addresses or addresses that don't match the pattern
    # Remove street number and apartment/unit numbers for better results
    simplified = address.gsub(/^\d+\s+/, '') # Remove leading street numbers
                        .gsub(/(?:#|apt|unit|ste|suite)\s*[\w-]+/i, '') # Remove apartment/unit designations
                        .gsub(/,\s*usa$/i, ', US') # Standardize USA to US
                        .strip
    
    if simplified != address
      Rails.logger.info("Simplified address from '#{address}' to '#{simplified}'")
    end
    
    simplified
  end
  
  # Fetch data from API endpoint
  # @param endpoint [String] API endpoint
  # @param params [Hash] Query parameters
  # @return [Hash] Parsed JSON response
  def fetch_from_api(endpoint, params)
    # Add API key to params
    params[:appid] = @api_key
    
    # Make the appropriate API request based on the endpoint type
    if endpoint.start_with?("geo")
      # For geocoding requests, use the full URL
      url = "#{GEO_API_URL}/#{endpoint.sub('geo/1.0/', '')}"
      uri_params = params.map { |k, v| "#{k}=#{v}" }.join("&")
      full_url = "#{url}?#{uri_params}"
      
      Rails.logger.info("Making Geocoding API request to: #{full_url.gsub(@api_key, '[REDACTED]')}")
      
      # Use the direct URL method for geocoding
      response = get_url(full_url)
    else
      # For weather requests, use the standard get method with base_url
      Rails.logger.info("Making Weather API request to: #{endpoint} with params: #{params.except(:appid).inspect}")
      response = get(endpoint, params: params)
    end
    
    Rails.logger.info("API response: #{response ? 'Success' : 'Nil'}")
    response
  rescue => e
    Rails.logger.error("API Error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    nil
  end
  
  # Normalize string for consistent caching
  # @param str [String] String to normalize
  # @return [String] Normalized string
  def normalize_string(str)
    # Normalize string by removing extra whitespace, downcasing, etc.
    str.to_s.strip.downcase.gsub(/\s+/, ' ')
  end
  
  # Generate a cache key for weather data
  # @param lat [Float] Latitude
  # @param lon [Float] Longitude
  # @return [String] Cache key
  def cache_key_for_coordinates(lat, lon)
    # Use the exact coordinates returned by the API
    "weather:coord:#{lat}:#{lon}"
  end
  
  # Get weather cache TTL from configuration
  # @return [Integer] Cache TTL in seconds
  def weather_cache_ttl
    Rails.configuration.x.weather.cache_ttl || 30.minutes
  end
end
