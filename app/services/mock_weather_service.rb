# app/services/mock_weather_service.rb

# Mock service for weather data to use during development and testing
# when the actual OpenWeatherMap API is not available
class MockWeatherService
  # Initialize the service (API key not actually used in mock)
  def initialize(api_key = nil)
    @api_key = api_key || 'mock_api_key'
    Rails.logger.debug "MockWeatherService initialized"
  end

  # Fetch current weather data by address
  # @param address [String] Address to get weather for
  # @param units [String] Temperature units ('imperial' for Fahrenheit, 'metric' for Celsius)
  # @return [Hash] Mock weather data
  def get_by_address(address, units: 'imperial')
    Rails.logger.debug "MockWeatherService.get_by_address called with: #{address}"
    
    # Extract zip code if present using the centralized service
    zip_code = ZipCodeExtractionService.extract_from_address(address)
    
    # For demo purposes, return weather data specific to known zip codes
    # or generate random data for others
    data = mock_weather_data_for(address, zip_code, units)
    
    Rails.logger.debug "Returning mock weather data for: #{address}"
    data
  end
  
  private
  
  # Generate mock weather data
  def mock_weather_data_for(address, zip_code, units)
    # Create some variety based on zip code or address to make it more realistic
    seed = zip_code ? zip_code.to_i : address.hash
    random = Random.new(seed)
    
    # Always generate temperatures in Fahrenheit (imperial units) first
    current_temp_f = 60 + random.rand(30)
    high_temp_f = current_temp_f + random.rand(15)
    low_temp_f = current_temp_f - random.rand(15)
    
    # Always convert to Celsius for storage (normalized format)
    # The view layer will handle conversion to Fahrenheit if needed
    current_temp = TemperatureConversionService.fahrenheit_to_celsius(current_temp_f)
    high_temp = TemperatureConversionService.fahrenheit_to_celsius(high_temp_f)
    low_temp = TemperatureConversionService.fahrenheit_to_celsius(low_temp_f)
    
    extended_forecast = mock_extended_forecast(random, units: units)
    
    {
      address: address,
      zip_code: zip_code || "12345",
      current_temp: current_temp,
      high_temp: high_temp,
      low_temp: low_temp,
      unit: units.to_s.downcase == 'metric' ? 'C' : 'F',
      conditions: ["Sunny", "Partly Cloudy", "Cloudy", "Light Rain", "Thunderstorms"].sample(random: random),
      extended_forecast: extended_forecast,
      queried_at: Time.now
    }
  end
  
  # Generate mock extended forecast
  def mock_extended_forecast(random, units: 'imperial')
    today = Date.today
    
    forecast_days = Rails.configuration.x.weather.forecast_days.times.map do |i|
      date = today + (i + 1).days
      
      # Generate temperatures in Fahrenheit first
      high_f = 60 + random.rand(30)
      low_f = 45 + random.rand(30)
      
      # Always convert to Celsius for storage (normalized format)
      # The view layer will handle conversion to Fahrenheit if needed
      high = TemperatureConversionService.fahrenheit_to_celsius(high_f)
      low = TemperatureConversionService.fahrenheit_to_celsius(low_f)
      
      {
        date: date.to_s,
        day_name: date.strftime('%A'),
        high: high,
        low: low,
        conditions: [random.rand(3) == 0 ? "Rainy" : "Sunny"],
        units: units
      }
    end
    
    forecast_days.to_json
  end
end
