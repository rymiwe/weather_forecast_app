# frozen_string_literal: true
require_relative '../clients/weather_api_client'
require_relative '../clients/mock_weather_api_client'
require_relative 'address_preprocessor_service'

# Service for finding or creating a forecast
class FindOrCreateForecastService
  # Initialize the service
  # @param address [String] Address to find or create a forecast for
  # @param request_ip [String] IP address of the request (for geolocation)
  def initialize(address:, request_ip: nil)
    @address = address
    @request_ip = request_ip
  end
  
  # Find or create a forecast
  # @return [Forecast, nil] Found or created forecast, or nil if failed
  def self.call(address:, request_ip: nil)
    new(address: address, request_ip: request_ip).call
  end
  
  # Find or create a forecast
  # @return [Forecast, nil] Found or created forecast, or nil if failed
  def call
    Rails.logger.info "FindOrCreateForecastService: Finding or creating forecast for address: #{@address}"
    return nil if @address.blank?
    
    # Preprocess the address for API lookup
    processed_address = AddressPreprocessorService.preprocess(@address)
    
    # Return nil with an error if geocoding failed
    if processed_address.nil?
      Rails.logger.error "FindOrCreateForecastService: Unable to geocode address: '#{@address}'"
      return Forecast.new.tap do |f|
        f.errors.add(:address, "Unable to find location. Please try a different search term.")
      end
    end
    
    Rails.logger.info "FindOrCreateForecastService: Using preprocessed address: '#{processed_address}' (original: '#{@address}')"
    
    # Find forecast by normalized processed address
    normalized = Forecast.normalize_address(processed_address)
    Rails.logger.info "FindOrCreateForecastService: Searching with normalized address: '#{normalized}'"
    forecast = Forecast.find_cached_by_address(normalized)
    
    if forecast.present?
      Rails.logger.info "FindOrCreateForecastService: Found forecast by normalized address: #{forecast.id}"
      # Mark this forecast as retrieved from cache
      forecast.from_cache = true
      # Store the API query for display purposes
      forecast.api_query = processed_address
    else
      Rails.logger.info "FindOrCreateForecastService: No forecast found by normalized address"
      # If no forecast was found, create a new one
      forecast = create_new_forecast(processed_address)
      Rails.logger.info "FindOrCreateForecastService: Create new forecast result: #{forecast ? 'Success' : 'Nil'}"
      # New forecasts are not from cache
      forecast.from_cache = false if forecast
      # Store the API query for display purposes
      forecast.api_query = processed_address if forecast
    end
    
    forecast
  end
  
  private
  
  # Create a new forecast
  # @param processed_address [String] Preprocessed address for API lookup
  # @return [Forecast, nil] Created forecast or nil if failed
  def create_new_forecast(processed_address)
    # Never use mock client in production regardless of environment settings
    if Rails.env.production?
      Rails.logger.info "FindOrCreateForecastService: In production, always using real client for address: #{@address}"
      return create_with_real_client(processed_address)
    end
    
    # In development/test, check Rails configuration
    use_mock = Rails.configuration.x.weather.use_mock_client
    
    if use_mock
      Rails.logger.info "FindOrCreateForecastService: Using mock client for address: #{@address}"
      create_with_mock_client(processed_address)
    else
      Rails.logger.info "FindOrCreateForecastService: Using real client for address: #{@address}"
      create_with_real_client(processed_address)
    end
  end
  
  # Create forecast with mock client
  # @param processed_address [String] Preprocessed address for API lookup
  # @return [Forecast, nil] Created forecast or nil if failed
  def create_with_mock_client(processed_address)
    client = MockWeatherApiClient.instance
    api_result = client.get_weather(address: processed_address)
    
    if api_result.nil?
      Rails.logger.error "FindOrCreateForecastService: Mock API returned nil for address: #{@address}"
      return nil
    end
    
    # Create a new forecast with the data from the mock client
    Forecast.create_from_api_response(processed_address, api_result)
  end
  
  # Create forecast with real client
  # @param processed_address [String] Preprocessed address for API lookup
  # @return [Forecast, nil] Created forecast or nil if failed
  def create_with_real_client(processed_address)
    client = WeatherApiClient.instance
    
    begin
      # Get weather data from the API using the preprocessed address
      api_result = client.get_weather(address: processed_address)
      Rails.logger.info("API fetch result: #{api_result ? 'Success' : 'Nil'}")
      
      if api_result.nil?
        Rails.logger.error "FindOrCreateForecastService: API returned nil for address: #{processed_address}"
        return nil
      end
      
      # Create a new forecast with the data from the API
      # Store the processed address version for consistent caching
      Forecast.create_from_api_response(processed_address, api_result)
    rescue StandardError => e
      Rails.logger.error "FindOrCreateForecastService: Error creating forecast: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end
end
