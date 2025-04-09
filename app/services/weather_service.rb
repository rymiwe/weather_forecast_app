# app/services/weather_service.rb
require 'net/http'
require 'json'

# Service class responsible for interacting with the OpenWeatherMap API
# to fetch current and forecast weather data based on location information.
class WeatherService
  # Base URL for OpenWeatherMap API
  BASE_URL = 'https://api.openweathermap.org/data/2.5'.freeze
  
  # Initialize the service with an API key
  # @param api_key [String] OpenWeatherMap API key
  def initialize(api_key = nil)
    @api_key = api_key || ENV['OPENWEATHERMAP_API_KEY']
    Rails.logger.debug "WeatherService initialized with API key: #{@api_key.present? ? 'PRESENT' : 'MISSING'}"
  end

  # Fetch current weather data by address
  # @param address [String] Address to get weather for
  # @return [Hash] Weather data or error information
  def get_by_address(address)
    Rails.logger.debug "WeatherService.get_by_address called with: #{address}"
    coordinates = geocode_address(address)
    Rails.logger.debug "Geocoded coordinates: #{coordinates.inspect}"
    return { error: 'Could not geocode address' } unless coordinates

    zip_code = get_zip_code(coordinates)
    Rails.logger.debug "Retrieved zip code: #{zip_code}"
    
    data = fetch_weather_data(coordinates)
    data[:zip_code] = zip_code
    data[:address] = address
    Rails.logger.debug "Final weather data: #{data.inspect}"
    data
  end

  private

  # Convert address to geographic coordinates
  # @param address [String] Address to geocode
  # @return [Hash, nil] Hash of lat and lon or nil if geocoding failed
  def geocode_address(address)
    encoded_address = URI.encode_www_form_component(address)
    uri = URI("https://api.openweathermap.org/geo/1.0/direct?q=#{encoded_address}&limit=1&appid=#{@api_key}")
    
    response = make_request(uri)
    return nil unless response && !response.empty?
    
    Rails.logger.debug "Geocoding response: #{response.inspect}"
    { lat: response[0]['lat'], lon: response[0]['lon'] }
  end

  # Retrieve zip code for coordinates
  # @param coordinates [Hash] Hash with lat and lon
  # @return [String, nil] Zip code or nil if not found
  def get_zip_code(coordinates)
    uri = URI("https://api.openweathermap.org/geo/1.0/reverse?lat=#{coordinates[:lat]}&lon=#{coordinates[:lon]}&limit=1&appid=#{@api_key}")
    
    response = make_request(uri)
    return nil unless response && !response.empty?
    
    Rails.logger.debug "Reverse geocoding response: #{response.inspect}"
    # Use the centralized ZIP code extraction service to extract postal code
    ZipCodeExtractionService.extract_from_location_data(response[0])
  end

  # Fetch weather data for coordinates
  # @param coordinates [Hash] Hash with lat and lon
  # @return [Hash] Weather data including current, high/low, and forecast
  def fetch_weather_data(coordinates)
    Rails.logger.debug "Fetching weather data for coordinates: #{coordinates.inspect}"
    # Get current weather
    current_uri = URI("#{BASE_URL}/weather?lat=#{coordinates[:lat]}&lon=#{coordinates[:lon]}&units=imperial&appid=#{@api_key}")
    current_data = make_request(current_uri)
    
    # Get 5-day forecast for high/low and extended forecast
    forecast_uri = URI("#{BASE_URL}/forecast?lat=#{coordinates[:lat]}&lon=#{coordinates[:lon]}&units=imperial&appid=#{@api_key}")
    forecast_data = make_request(forecast_uri)
    
    Rails.logger.debug "Current weather data: #{current_data.inspect}"
    Rails.logger.debug "Forecast weather data: #{forecast_data.inspect}"
    # Process and format the data
    process_weather_data(current_data, forecast_data)
  end

  # Process raw API responses into a formatted hash
  # @param current_data [Hash] Current weather data
  # @param forecast_data [Hash] Forecast weather data
  # @return [Hash] Processed weather information
  def process_weather_data(current_data, forecast_data)
    return { error: 'Failed to retrieve weather data' } unless current_data && forecast_data
    
    Rails.logger.debug "Processing weather data..."
    # Get today's high and low from forecast data
    todays_temps = extract_todays_temps(forecast_data)
    
    # Format extended forecast for next 5 days
    extended_forecast = format_extended_forecast(forecast_data)
    
    {
      current_temp: current_data['main']['temp'],
      high_temp: todays_temps[:high],
      low_temp: todays_temps[:low],
      conditions: current_data['weather'][0]['description'],
      extended_forecast: extended_forecast,
      queried_at: Time.now
    }
  end

  # Extract today's high and low temperatures from forecast data
  # @param forecast_data [Hash] Forecast data from API
  # @return [Hash] High and low temperatures
  def extract_todays_temps(forecast_data)
    today = Date.today
    todays_forecasts = forecast_data['list'].select do |forecast|
      forecast_date = Time.at(forecast['dt']).to_date
      forecast_date == today
    end
    
    temps = todays_forecasts.map { |f| f['main']['temp'] }
    
    Rails.logger.debug "Today's temps: #{temps.inspect}"
    { high: temps.max || 0, low: temps.min || 0 }
  end

  # Format extended forecast for display
  # @param forecast_data [Hash] Forecast data from API
  # @return [String] JSON string of formatted forecast data
  def format_extended_forecast(forecast_data)
    daily_forecasts = {}
    
    forecast_data['list'].each do |forecast|
      time = Time.at(forecast['dt'])
      date = time.to_date.to_s
      
      daily_forecasts[date] ||= {
        date: date,
        day_name: time.strftime('%A'),
        high: -Float::INFINITY,
        low: Float::INFINITY,
        conditions: []
      }
      
      # Update high and low temperatures
      daily_forecasts[date][:high] = [daily_forecasts[date][:high], forecast['main']['temp']].max
      daily_forecasts[date][:low] = [daily_forecasts[date][:low], forecast['main']['temp']].min
      
      # Add unique weather conditions
      condition = forecast['weather'][0]['description']
      daily_forecasts[date][:conditions] << condition unless daily_forecasts[date][:conditions].include?(condition)
    end
    
    Rails.logger.debug "Daily forecasts: #{daily_forecasts.inspect}"
    # Convert to array, sort by date, and remove today (since we already show it)
    result = daily_forecasts.values.sort_by { |f| f[:date] }
    result.shift if result.any? && result[0][:date] == Date.today.to_s
    
    # Take only next 5 days
    result = result.take(5)
    
    Rails.logger.debug "Extended forecast: #{result.inspect}"
    # Convert to JSON string
    result.to_json
  end

  # Make HTTP request and return parsed JSON
  # @param uri [URI] Request URI
  # @return [Hash, nil] Parsed JSON response or nil if request failed
  def make_request(uri)
    Rails.logger.debug "Making API request to: #{uri}"
    response = Net::HTTP.get_response(uri)
    
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "API request failed with code: #{response.code}, message: #{response.message}"
      return nil
    end
    
    Rails.logger.debug "API response: #{response.body}"
    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("API request error: #{e.message}")
    nil
  end
end
