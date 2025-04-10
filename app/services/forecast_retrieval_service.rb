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
    new(address, units, request_ip).retrieve
  end
  
  def initialize(address, units, request_ip)
    @address = address
    @units = units || default_units(request_ip)
    @request_ip = request_ip
    @zip_code = ZipCodeExtractionService.extract_from_address(address)
  end
  
  # Main method to retrieve forecast
  # Tries cache first, then API if needed
  def retrieve
    # Try to find in cache first
    if @zip_code
      cached_forecast = Forecast.find_cached(@zip_code)
      return cached_forecast if cached_forecast
    end
    
    # If not in cache, fetch from API
    fetch_from_api
  rescue StandardError => e
    # Use centralized error handling
    error_context = { address: @address, zip_code: @zip_code, ip: @request_ip }
    ErrorHandlingService.handle_api_error(e, error_context)
    nil
  end
  
  private
  
  # Determine default temperature units
  def default_units(request_ip)
    Rails.configuration.x.weather.default_unit || 
      UserLocationService.units_for_ip(request_ip)
  end
  
  # Fetch forecast from API
  def fetch_from_api
    # Verify API key
    api_key = ENV['OPENWEATHERMAP_API_KEY']
    raise ErrorHandlingService::ConfigurationError, "Weather API key is missing" unless api_key
    
    # No longer using rate limiting prevention, just handle errors gracefully
    
    # Fetch data from service
    weather_service = MockWeatherService.new(api_key)
    weather_data = if @request_ip
                    weather_service.get_by_address(@address, units: @units, ip: @request_ip)
                  else
                    weather_service.get_by_address(@address, units: @units)
                  end
    
    # If API responds with rate limit error
    if weather_data[:error] && weather_data[:error].to_s.match?(/rate limit|too many requests/i)
      ErrorHandlingService.handle_rate_limit_exceeded('openweathermap', "Rate limit exceeded for #{@address}")
    elsif weather_data[:error]
      Rails.logger.error "API Error: #{weather_data[:error]}"
      return nil
    end
    
    # Extract relevant data and create forecast with normalized temperatures in Celsius
    # Convert temperatures to Celsius if they were provided in imperial units
    current_temp = weather_data[:current_temp]
    high_temp = weather_data[:high_temp]
    low_temp = weather_data[:low_temp]
    
    # Save temperatures in Celsius (our normalized format) as integers
    if @units == 'imperial' && !current_temp.nil?
      current_temp = TemperatureConversionService.fahrenheit_to_celsius(current_temp.to_f)
      high_temp = high_temp.nil? ? nil : TemperatureConversionService.fahrenheit_to_celsius(high_temp.to_f)
      low_temp = low_temp.nil? ? nil : TemperatureConversionService.fahrenheit_to_celsius(low_temp.to_f)
    elsif !current_temp.nil?
      # Ensure Celsius values are also rounded integers
      current_temp = current_temp.to_f.round
      high_temp = high_temp.nil? ? nil : high_temp.to_f.round
      low_temp = low_temp.nil? ? nil : low_temp.to_f.round
    end
    
    # Create the forecast with normalized temperatures
    forecast = Forecast.create(
      address: @address,
      zip_code: @zip_code,
      current_temp: current_temp,
      high_temp: high_temp,
      low_temp: low_temp,
      conditions: weather_data[:conditions].is_a?(Array) ? weather_data[:conditions].first : weather_data[:conditions],
      extended_forecast: weather_data[:extended_forecast],
      queried_at: Time.current
    )
    
    # Handle validation errors properly if the forecast couldn't be saved
    unless forecast.persisted?
      error_context = { address: @address, data: weather_data }
      ErrorHandlingService.handle_validation_error(forecast, error_context)
    end
    
    forecast
  end
end
