# Mock OpenWeatherMapClient for testing
class MockOpenWeatherMapClient
  def initialize(api_key = nil)
    # No actual API calls will be made
  end
  
  def get_weather(address:, units: 'metric')
    # Return mock data based on the address
    case address.to_s.downcase
    when /san diego/, /london/, /seattle/, /denver/, /miami/, /san francisco/
      generate_mock_weather_data(address, units)
    else
      raise "Could not find location: #{address}"
    end
  end
  
  private
  
  def generate_mock_weather_data(address, units)
    is_us = address.to_s.match?(/united states|usa|u\.s\.a\.|america|california|texas|florida|washington|oregon|new york|san diego|seattle|denver|miami|san francisco/i)
    
    temp_multiplier = units == 'imperial' ? 1.8 : 1.0
    temp_offset = units == 'imperial' ? 32 : 0
    
    # Base temperatures in Celsius
    current_temp = 20
    high_temp = 25
    low_temp = 15
    
    # Adjust for different cities and convert units if needed
    case address.to_s.downcase
    when /san diego/
      condition = "sunny"
      current_temp = 25
      high_temp = 28
      low_temp = 18
    when /seattle/
      condition = "rain"
      current_temp = 12
      high_temp = 15
      low_temp = 8
    when /denver/
      condition = "snow"
      current_temp = 0
      high_temp = 5
      low_temp = -5
    when /london/
      condition = "cloudy"
      current_temp = 14
      high_temp = 16
      low_temp = 10
    when /miami/
      condition = "thunderstorm"
      current_temp = 27
      high_temp = 32
      low_temp = 24
    when /san francisco/
      condition = "fog"
      current_temp = 15
      high_temp = 18
      low_temp = 12
    else
      condition = "partly cloudy"
    end
    
    # Convert temperatures if needed
    current_temp = (current_temp * temp_multiplier + temp_offset).round if units == 'imperial'
    high_temp = (high_temp * temp_multiplier + temp_offset).round if units == 'imperial'
    low_temp = (low_temp * temp_multiplier + temp_offset).round if units == 'imperial'
    
    # Generate mock API response structure
    {
      coordinates: {
        lat: 0.0,
        lon: 0.0,
        name: address.split(',').first,
        country: is_us ? 'US' : 'GB'
      },
      current_weather: {
        'main' => {
          'temp' => current_temp,
          'temp_min' => low_temp,
          'temp_max' => high_temp
        },
        'weather' => [
          { 'main' => condition.capitalize, 'description' => condition }
        ]
      },
      forecast: {
        'list' => generate_mock_forecast_days(5, current_temp, high_temp, low_temp, condition, units)
      }
    }
  end
  
  def generate_mock_forecast_days(days, base_temp, base_high, base_low, base_condition, units)
    forecast_days = []
    
    days.times do |i|
      day_temp = base_temp + rand(-3..3)
      day_high = base_high + rand(-2..2)
      day_low = base_low + rand(-2..2)
      
      # Vary conditions slightly
      conditions = ['sunny', 'cloudy', 'partly cloudy', 'rain', 'light rain', 'snow', 'fog', 'thunderstorm']
      day_condition = i.zero? ? base_condition : conditions.sample
      
      forecast_days << {
        'dt' => (Time.now + i.days).to_i,
        'main' => {
          'temp' => day_temp,
          'temp_min' => day_low,
          'temp_max' => day_high
        },
        'weather' => [
          { 'main' => day_condition.capitalize, 'description' => day_condition }
        ],
        'dt_txt' => (Time.now + i.days).strftime('%Y-%m-%d %H:%M:%S')
      }
    end
    
    forecast_days
  end
end
