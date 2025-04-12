# frozen_string_literal: true
require_relative '../clients/open_weather_map_client'
require_relative '../clients/mock_open_weather_map_client'
require_relative '../clients/weather_api_client'
require_relative '../clients/mock_weather_api_client'

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
    
    # Find forecast by normalized address
    normalized = Forecast.normalize_address(@address)
    Rails.logger.info "FindOrCreateForecastService: Searching with normalized address: '#{normalized}'"
    forecast = Forecast.find_cached_by_address(normalized)
    
    if forecast.present?
      Rails.logger.info "FindOrCreateForecastService: Found forecast by normalized address: #{forecast.id}"
      # Mark this forecast as retrieved from cache
      forecast.from_cache = true
    else
      Rails.logger.info "FindOrCreateForecastService: No forecast found by normalized address"
      # If no forecast was found, create a new one
      forecast = create_new_forecast
      Rails.logger.info "FindOrCreateForecastService: Create new forecast result: #{forecast ? 'Success' : 'Nil'}"
      # New forecasts are not from cache
      forecast.from_cache = false if forecast
    end
    
    forecast
  end
  
  private
  
  # Create a new forecast
  # @return [Forecast, nil] Created forecast or nil if failed
  def create_new_forecast
    # Never use mock client in production regardless of environment settings
    if Rails.env.production?
      Rails.logger.info "FindOrCreateForecastService: In production, always using real client for address: #{@address}"
      return create_with_real_client
    end
    
    # In development/test, check environment setting
    use_mock = ENV.fetch('USE_MOCK_WEATHER_CLIENT', 'true').downcase == 'true'
    
    if use_mock
      Rails.logger.info "FindOrCreateForecastService: Using mock client for address: #{@address}"
      create_with_mock_client
    else
      Rails.logger.info "FindOrCreateForecastService: Using real client for address: #{@address}"
      create_with_real_client
    end
  end
  
  # Create forecast with mock client
  # @return [Forecast, nil] Created forecast or nil if failed
  def create_with_mock_client
    client = MockWeatherApiClient.instance
    api_result = client.get_weather(address: @address)
    
    if api_result.nil?
      Rails.logger.error "FindOrCreateForecastService: Mock API returned nil for address: #{@address}"
      return nil
    end
    
    # Create a new forecast with the data from the mock client
    Forecast.create_from_api_response(@address, api_result)
  end
  
  # Create forecast with real client
  # @return [Forecast, nil] Created forecast or nil if failed
  def create_with_real_client
    client = WeatherApiClient.instance
    
    begin
      # Get weather data from the API
      api_result = client.get_weather(address: @address)
      Rails.logger.info("API fetch result: #{api_result ? 'Success' : 'Nil'}")
      
      if api_result.nil?
        Rails.logger.error "FindOrCreateForecastService: API returned nil for address: #{@address}"
        return nil
      end
      
      # Create a new forecast with the data from the API
      Forecast.create_from_api_response(@address, api_result)
    rescue StandardError => e
      Rails.logger.error "FindOrCreateForecastService: Error creating forecast: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end
end
