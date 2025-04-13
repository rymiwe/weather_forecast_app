# frozen_string_literal: true

# Helper module for testing WeatherAPI-related components
module WeatherApiTestHelpers
  # Generate a realistic mock response from WeatherAPI.com
  # @param location [String] Name of the location for the mock data
  # @param options [Hash] Options to customize the mock data
  # @return [Hash] Mock API response with proper structure
  def mock_weather_api_response(location, options = {})
    # Default options with sensible values
    defaults = {
      temp_c: 22.5,
      temp_f: 72.5,
      condition: 'Partly cloudy',
      condition_code: 1003,
      high_temp_c: 25.0,
      high_temp_f: 77.0,
      low_temp_c: 18.0,
      low_temp_f: 64.4,
      days: 3,
      lat: 37.7749,
      lon: -122.4194,
      region: 'California',
      country: 'United States of America'
    }
    
    # Merge provided options with defaults
    opts = defaults.merge(options)
    
    # Build a properly structured response matching WeatherAPI.com format
    {
      'location' => {
        'name' => location,
        'region' => opts[:region],
        'country' => opts[:country],
        'lat' => opts[:lat],
        'lon' => opts[:lon],
        'tz_id' => 'America/Los_Angeles',
        'localtime_epoch' => Time.now.to_i,
        'localtime' => Time.now.strftime('%Y-%m-%d %H:%M')
      },
      'current' => {
        'temp_c' => opts[:temp_c],
        'temp_f' => opts[:temp_f],
        'condition' => {
          'text' => opts[:condition],
          'icon' => "//cdn.weatherapi.com/weather/64x64/day/#{opts[:condition_code]}.png",
          'code' => opts[:condition_code]
        },
        'wind_mph' => 5.6,
        'wind_kph' => 9.0,
        'humidity' => 65,
        'cloud' => 25,
        'feelslike_c' => opts[:temp_c] + 1.0,
        'feelslike_f' => opts[:temp_f] + 2.0,
        'uv' => 4.0
      },
      'forecast' => {
        'forecastday' => generate_forecast_days(opts[:days], opts)
      }
    }
  end
  
  private
  
  # Generate an array of forecast days for the mock response
  # @param count [Integer] Number of days to generate
  # @param options [Hash] Options to use when generating forecast data
  # @return [Array] Array of forecast day hashes
  def generate_forecast_days(count, options)
    (0...count).map do |offset|
      date = Date.today + offset
      # Adjust temperatures to simulate a trend over days
      temp_adjustment = (rand(-3.0..3.0)).round(1)
      
      {
        'date' => date.iso8601,
        'date_epoch' => date.to_time.to_i,
        'day' => {
          'maxtemp_c' => options[:high_temp_c] + temp_adjustment,
          'maxtemp_f' => options[:high_temp_f] + temp_adjustment * 1.8,
          'mintemp_c' => options[:low_temp_c] + temp_adjustment,
          'mintemp_f' => options[:low_temp_f] + temp_adjustment * 1.8,
          'avgtemp_c' => (options[:high_temp_c] + options[:low_temp_c]) / 2.0 + temp_adjustment,
          'avgtemp_f' => (options[:high_temp_f] + options[:low_temp_f]) / 2.0 + temp_adjustment * 1.8,
          'condition' => {
            'text' => options[:condition],
            'icon' => "//cdn.weatherapi.com/weather/64x64/day/#{options[:condition_code]}.png",
            'code' => options[:condition_code]
          },
          'uv' => 4.0,
          'daily_chance_of_rain' => offset.zero? ? 15 : 25 + offset * 5
        },
        'astro' => {
          'sunrise' => '06:45 AM',
          'sunset' => '07:30 PM',
          'moonrise' => '08:15 PM',
          'moonset' => '06:15 AM',
          'moon_phase' => 'Waxing Gibbous',
          'moon_illumination' => '78'
        },
        'hour' => [] # We don't need hourly forecast for most tests
      }
    end
  end
end

RSpec.configure do |config|
  config.include WeatherApiTestHelpers
end
