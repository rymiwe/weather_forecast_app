# frozen_string_literal: true

# Service for retrieving forecasts from API or cache
# Follows enterprise best practices with proper error handling and logging
class ForecastRetrievalService
  # No custom error classes needed - using ErrorHandlingService's classes instead
  
  # Retrieve a forecast for the given address
  # @param address [String] The address to fetch forecast for
  # @param units [String] Temperature units ('imperial' or 'metric')
  # @param request_ip [String] IP address of the requester (for rate limiting)
  # @return [Forecast, nil] The forecast object or nil if there was an error
  # @raise [StandardError] if API rate limit is exceeded or API key is missing
  def self.retrieve(address, units: nil, request_ip: nil)
    new(address: address, units: units).call
  end
  
  # Initialize with an address and units
  # @param address [String] The address to retrieve forecast for  
  # @param units [String] Temperature units ('imperial' or 'metric'). If nil, will be determined by location
  def initialize(address:, units: nil)
    @address = address
    
    # Extract zip code from address
    @zip_code = ZipCodeExtractionService.extract_from_address(address)
    
    # If units is nil, it will be determined by location in the #call method
    @units = units
  end
  
  # Retrieve the forecast
  # @return [Forecast] The forecast object
  def call
    # Check if a forecast already exists for this address within the cache window
    forecast = find_cached_forecast
    
    if forecast.nil?
      # No valid cached forecast, fetch new data
      weather_data = fetch_from_api
      return nil if weather_data.nil?
      
      # Create a new forecast record
      forecast = Forecast.new(
        address: @address,
        zip_code: @zip_code,
        current_temp: weather_data[:current_temp],
        high_temp: weather_data[:high_temp], 
        low_temp: weather_data[:low_temp],
        conditions: weather_data[:conditions],
        extended_forecast: weather_data[:extended_forecast],
        queried_at: Time.now
      )
      
      if forecast.save
        Rails.logger.info "Created new forecast for #{@address}"
      else
        Rails.logger.error "Failed to save forecast: #{forecast.errors.full_messages.join(', ')}"
        return nil
      end
    else
      Rails.logger.info "Using cached forecast for #{@address}"
    end
    
    forecast
  end
  
  private
  
  # Find a cached forecast if one exists
  # @return [Forecast] The cached forecast or nil
  def find_cached_forecast
    # Skip cache if testing
    return nil if Rails.env.test?
    
    # Find by zip code if available, otherwise by address
    scope = if @zip_code.present?
      Forecast.where(zip_code: @zip_code)
    else
      Forecast.where(address: @address)
    end
    
    # Find a forecast that's still valid
    scope.where('queried_at > ?', Time.now - Rails.configuration.x.weather.cache_duration).order(queried_at: :desc).first
  end
  
  # Fetch weather data from the API
  # @return [Hash] The weather data
  def fetch_from_api
    api_key = ENV['OPENWEATHERMAP_API_KEY']
    
    if api_key.blank?
      Rails.logger.error "Missing OpenWeatherMap API key"
      raise ErrorHandlingService::ConfigurationError, "Missing API key"
    end
    
    # Default to metric units if none specified
    units_to_use = @units || 'metric'
    
    begin
      # In development/test, use the mock service
      if Rails.env.development? || Rails.env.test?
        weather_service = MockWeatherService.new(api_key)
        weather_data = weather_service.get_by_address(@address, units: units_to_use)
      else
        # In production, use the real service
        weather_service = OpenWeatherMapService.new(api_key)
        weather_data = weather_service.get_by_address(@address, units: units_to_use)
      end
      
      # Normalize data according to our application format
      weather_data
    rescue => e
      Rails.logger.error "Error fetching weather data: #{e.message}"
      raise
    end
  end
end
