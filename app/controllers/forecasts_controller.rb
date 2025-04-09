class ForecastsController < ApplicationController
  # GET /forecasts - Display search form
  def index
    # Initialize empty search form
    @address = params[:address]
    # Get temperature units preference (from session or IP-based)
    @temperature_units = temperature_units
    
    # If address is provided, search for forecast
    if @address.present?
      # Try to find forecast in cache
      zip_code = extract_zip_code(@address)
      @forecast = Forecast.find_cached(zip_code) if zip_code
      
      # If not in cache or no zip code, fetch from API
      if @forecast.nil?
        @forecast = fetch_forecast_data(@address)
        # Log for debugging
        Rails.logger.debug "API fetch result: #{@forecast.inspect}"
      end
      
      # Render the forecast partial via Turbo Stream if it's an AJAX request
      respond_to do |format|
        format.html # Render the default index template
        format.turbo_stream
      end
    end
  end

  # GET /forecasts/:id - Display a specific forecast
  def show
    @forecast = Forecast.find(params[:id])
    # Set temperature units preference if provided
    session[:temperature_units] = params[:units] if params[:units].present?
    # Get current temperature units
    @temperature_units = temperature_units
  rescue ActiveRecord::RecordNotFound
    redirect_to forecasts_path, alert: "Forecast not found"
  end
  
  private
  
  # Determine temperature units preference
  # Uses: 1) User preference in session, 2) Environment setting, 3) IP-based detection
  # @return [String] 'imperial' or 'metric'
  def temperature_units
    # Priority: User preference > Environment setting > IP-based detection
    session[:temperature_units] || 
      Rails.configuration.x.weather.default_unit || 
      UserLocationService.units_for_ip(request.remote_ip)
  end
  
  # Extract zip code from address string
  # @param address [String] The address to parse
  # @return [String, nil] The zip code or nil if not found
  def extract_zip_code(address)
    # Basic US zip code extraction
    match = address.to_s.match(/\b\d{5}(?:-\d{4})?\b/)
    match[0] if match
  end
  
  # Fetch forecast data from API and store in database
  # @param address [String] The address to fetch forecast for
  # @return [Forecast] The forecast object
  def fetch_forecast_data(address)
    # Get API key from environment
    api_key = ENV['OPENWEATHERMAP_API_KEY']
    
    # Return error if API key is missing
    unless api_key
      flash.now[:alert] = "Weather API key is missing. Please configure it in your environment."
      return nil
    end
    
    # Check if we're within API rate limits
    unless ApiRateLimiter.allow_request?('openweathermap')
      flash.now[:alert] = "API rate limit exceeded. Please try again in a minute."
      Rails.logger.warn "API rate limit exceeded for request: #{address}"
      return nil
    end
    
    # Fetch weather data from service
    # Using MockWeatherService since the real API is returning 401 errors
    weather_service = MockWeatherService.new(api_key)
    # Pass temperature units preference to get correct format
    weather_data = weather_service.get_by_address(address, units: temperature_units)
    
    if weather_data[:error]
      flash.now[:alert] = "Error retrieving forecast: #{weather_data[:error]}"
      Rails.logger.error "API Error: #{weather_data[:error]}"
      return nil
    end
    
    # Create and save forecast
    @forecast = Forecast.create_from_weather_data(weather_data)
    
    # Handle validation errors
    unless @forecast.persisted?
      flash.now[:alert] = "Could not save forecast: #{@forecast.errors.full_messages.join(', ')}"
      Rails.logger.error "Forecast save error: #{@forecast.errors.full_messages.join(', ')}"
    end
    
    @forecast
  end
end
