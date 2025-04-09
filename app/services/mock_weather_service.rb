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
    
    # Extract zip code if present
    zip_code = extract_zip_code_from_address(address)
    
    # For demo purposes, return weather data specific to known zip codes
    # or generate random data for others
    data = mock_weather_data_for(address, zip_code, units)
    
    Rails.logger.debug "Returning mock weather data for: #{address}"
    data
  end
  
  private
  
  # Extract zip code from address
  def extract_zip_code_from_address(address)
    match = address.to_s.match(/\b\d{5}(?:-\d{4})?\b/)
    match ? match[0] : nil
  end
  
  # Generate mock weather data
  def mock_weather_data_for(address, zip_code, units)
    # Create some variety based on zip code or address to make it more realistic
    seed = zip_code ? zip_code.to_i : address.hash
    random = Random.new(seed)
    
    # Generate temperatures in Fahrenheit (imperial units)
    current_temp_f = 50 + random.rand(40)
    high_temp_f = current_temp_f + 5 + random.rand(10)
    low_temp_f = current_temp_f - 5 - random.rand(15)
    
    # Convert to Celsius if metric units requested
    if units.to_s.downcase == 'metric'
      current_temp = fahrenheit_to_celsius(current_temp_f)
      high_temp = fahrenheit_to_celsius(high_temp_f)
      low_temp = fahrenheit_to_celsius(low_temp_f)
    else
      current_temp = current_temp_f
      high_temp = high_temp_f
      low_temp = low_temp_f
    end
    
    extended_forecast = mock_extended_forecast(random, units: units)
    
    {
      address: address,
      zip_code: zip_code || "12345",
      current_temp: current_temp,
      high_temp: high_temp,
      low_temp: low_temp,
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
      high_f = 45 + random.rand(40)
      low_f = 30 + random.rand(30)
      
      # Convert if metric requested
      high = (units.to_s.downcase == 'metric') ? fahrenheit_to_celsius(high_f) : high_f
      low = (units.to_s.downcase == 'metric') ? fahrenheit_to_celsius(low_f) : low_f
      
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
  
  # Convert temperature from Fahrenheit to Celsius
  # @param fahrenheit [Float] Temperature in Fahrenheit
  # @return [Float] Temperature in Celsius, rounded to one decimal
  def fahrenheit_to_celsius(fahrenheit)
    ((fahrenheit - 32) * 5.0 / 9.0).round(1)
  end
end
