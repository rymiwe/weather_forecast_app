# frozen_string_literal: true
require_relative '../clients/open_weather_map_client'
require_relative '../clients/mock_open_weather_map_client'

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
    
    # Look for an existing forecast by zip code first
    zip_code = extract_zip_code
    forecast = Forecast.find_cached(zip_code) if zip_code.present?
    
    # If no forecast was found, create a new one
    if forecast.nil?
      forecast = create_new_forecast
      Rails.logger.info "FindOrCreateForecastService: Create new forecast result: #{forecast ? 'Success' : 'Nil'}"
    end
    
    forecast
  end
  
  private
  
  # Extract zip code from address
  # @return [String, nil] Extracted zip code or nil
  def extract_zip_code
    ZipCodeExtractionService.extract_from_address(@address)
  end
  
  # Create a new forecast
  # @return [Forecast, nil] Created forecast or nil if failed
  def create_new_forecast
    # Determine whether to use mock client based on environment setting
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
    client = MockOpenWeatherMapClient.instance
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
    client = OpenWeatherMapClient.instance
    
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
