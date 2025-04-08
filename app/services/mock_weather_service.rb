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
  # @return [Hash] Mock weather data
  def get_by_address(address)
    Rails.logger.debug "MockWeatherService.get_by_address called with: #{address}"
    
    # Extract zip code if present
    zip_code = extract_zip_code_from_address(address)
    
    # For demo purposes, return weather data specific to known zip codes
    # or generate random data for others
    data = mock_weather_data_for(address, zip_code)
    
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
  def mock_weather_data_for(address, zip_code)
    # Create some variety based on zip code or address to make it more realistic
    seed = zip_code ? zip_code.to_i : address.hash
    random = Random.new(seed)
    
    current_temp = 50 + random.rand(40)
    high_temp = current_temp + 5 + random.rand(10)
    low_temp = current_temp - 5 - random.rand(15)
    
    extended_forecast = mock_extended_forecast(random)
    
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
  def mock_extended_forecast(random)
    today = Date.today
    
    forecast_days = 5.times.map do |i|
      date = today + (i + 1).days
      
      {
        date: date.to_s,
        day_name: date.strftime('%A'),
        high: 45 + random.rand(40),
        low: 30 + random.rand(30),
        conditions: [random.rand(3) == 0 ? "Rainy" : "Sunny"]
      }
    end
    
    forecast_days.to_json
  end
end
