# frozen_string_literal: true

require_relative 'service_base'

# Service for retrieving weather forecasts
# Handles caching, weather API interactions, and error handling
class ForecastRetrievalService
  include ServiceBase
  
  # Retrieve a forecast from the weather service or cache
  # @param address [String] The address to get weather for
  # @param request_ip [String] The IP address of the requester (optional)
  # @return [Forecast] The forecast object
  def self.retrieve(address, request_ip: nil)
    return nil if address.blank?
    
    # Create service and call
    new(address: address, request_ip: request_ip).call
  end

  # Initialize with the address
  # @param address [String] The address to get weather for
  # @param request_ip [String] The IP address of the requester (optional)
  def initialize(address:, request_ip: nil)
    @address = address
    @request_ip = request_ip
  end

  # Retrieve forecast data
  # @return [Forecast] The forecast object
  def call
    run_callbacks :call do
      # Try to find a cached forecast first
      zip_code = extract_zip_code(@address)
      forecast = Forecast.find_cached(zip_code) if zip_code.present?
      
      # If no cached forecast, get new data
      unless forecast
        # Get weather data (always in metric/Celsius)
        weather_data = weather_client_for_environment.get_weather(address: @address)
        return nil unless weather_data
        
        # Create a forecast from the weather data
        forecast = create_forecast_from_weather_data(weather_data)
      end
      
      forecast
    end
  end
  
  private
  
  # Extract zip code from address
  # @param address [String] The address to extract zip code from
  # @return [String] The zip code
  def extract_zip_code(address)
    ZipCodeExtractionService.extract_from_address(address)
  end
  
  # Create a forecast from the weather data
  # @param weather_data [Hash] The weather data
  # @return [Forecast] The forecast object
  def create_forecast_from_weather_data(weather_data)
    # Extract current weather data
    current = weather_data[:current_weather]
    forecast = weather_data[:forecast]
    
    # Extract current weather data
    current_temp = current['main']['temp']
    conditions = current['weather'][0]['description']
    high_temp = current['main']['temp_max']
    low_temp = current['main']['temp_min']
    
    # Extract forecast days
    forecast_days = extract_forecast_days(forecast['list'])
    
    # Create a new forecast record
    forecast = Forecast.new(
      address: @address,
      zip_code: extract_zip_code(@address),
      current_temp: current_temp,
      high_temp: high_temp,
      low_temp: low_temp,
      conditions: conditions,
      extended_forecast: forecast_days.to_json,
      queried_at: Time.now
    )
    
    if forecast.save
      Rails.logger.info "Created new forecast for #{@address}"
    else
      Rails.logger.error "Failed to save forecast: #{forecast.errors.full_messages.join(', ')}"
      return nil
    end
    
    forecast
  end
  
  # Extract forecast days from the API response
  # @param forecast_list [Array] List of forecast periods
  # @return [Array] Array of daily forecast data
  def extract_forecast_days(forecast_list)
    days = {}
    
    # Group forecast periods by day
    forecast_list.each do |period|
      # Convert Unix timestamp to Time object
      time = Time.at(period['dt'])
      date = time.strftime('%Y-%m-%d')
      
      # Initialize the day if it doesn't exist
      days[date] ||= {
        'date' => date,
        'high' => period['main']['temp_max'],
        'low' => period['main']['temp_min'],
        'conditions' => period['weather'][0]['description']
      }
      
      # Update high and low temps if necessary
      days[date]['high'] = [days[date]['high'], period['main']['temp_max']].max
      days[date]['low'] = [days[date]['low'], period['main']['temp_min']].min
    end
    
    # Convert hash to array and limit to 5 days
    days.values.sort_by { |day| day['date'] }[1..5]
  end
  
  # Get the appropriate weather client based on environment
  # @return [OpenWeatherMapClient, MockOpenWeatherMapClient] The weather client
  def weather_client_for_environment
    if Rails.configuration.x.weather.use_mock_client
      # Use the mock client in development/test
      require_dependency 'app/clients/mock_open_weather_map_client'
      MockOpenWeatherMapClient.instance
    else
      # Use the real client in production
      require_dependency 'app/clients/open_weather_map_client'
      OpenWeatherMapClient.instance
    end
  end
end
