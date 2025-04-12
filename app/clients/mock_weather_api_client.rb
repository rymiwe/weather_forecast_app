# frozen_string_literal: true
require 'singleton'
require_relative 'weather_api_client'

# Mock client for development/testing that mimics the WeatherAPI.com client behavior
class MockWeatherApiClient
  include Singleton
  
  # Get mock weather data for a given address
  # @param address [String] The address to get weather for
  # @return [Hash] Weather data
  def get_weather(address:)
    Rails.logger.info "MockWeatherApiClient: Getting mock weather for address: #{address}"
    
    # Create a mock response that matches the WeatherAPI.com structure
    # but with deterministic data based on the address
    {
      current_weather: mock_current_weather(address),
      forecast: mock_forecast(address),
      location: mock_location(address)
    }
  end
  
  private
  
  def mock_current_weather(address)
    # Generate deterministic temperature based on address
    temp_base = address.to_s.sum % 15 + 15 # 15-30 degrees C
    
    {
      'name' => extract_city(address),
      'region' => extract_region(address),
      'country' => 'United States of America',
      'lat' => 34.0 + (address.to_s.sum % 10),
      'lon' => -118.0 - (address.to_s.sum % 10),
      'temp_c' => temp_base,
      'temp_f' => (temp_base * 9 / 5) + 32,
      'condition' => {
        'text' => mock_condition_text(address),
        'icon' => '//cdn.weatherapi.com/weather/64x64/day/116.png',
        'code' => 1000 + (address.to_s.sum % 30)
      },
      'wind_kph' => 10 + (address.to_s.sum % 20),
      'wind_mph' => 6 + (address.to_s.sum % 12),
      'wind_dir' => %w[N NE E SE S SW W NW][address.to_s.sum % 8],
      'humidity' => 40 + (address.to_s.sum % 40),
      'cloud' => (address.to_s.sum % 100),
      'feelslike_c' => temp_base - 2,
      'feelslike_f' => ((temp_base - 2) * 9 / 5) + 32,
      'vis_km' => 10,
      'vis_miles' => 6,
      'uv' => 4,
      'gust_mph' => 15,
      'gust_kph' => 24.1
    }
  end
  
  def mock_forecast(address)
    # Create deterministic forecast for next 5 days
    base_temp = address.to_s.sum % 15 + 15
    
    {
      'forecastday' => (0..4).map do |day_offset|
        date = Date.today + day_offset
        {
          'date' => date.to_s,
          'date_epoch' => date.to_time.to_i,
          'day' => {
            'maxtemp_c' => base_temp + day_offset + 5,
            'maxtemp_f' => ((base_temp + day_offset + 5) * 9 / 5) + 32,
            'mintemp_c' => base_temp + day_offset - 5,
            'mintemp_f' => ((base_temp + day_offset - 5) * 9 / 5) + 32,
            'avgtemp_c' => base_temp + day_offset,
            'avgtemp_f' => ((base_temp + day_offset) * 9 / 5) + 32,
            'condition' => {
              'text' => mock_day_condition(day_offset, address),
              'icon' => '//cdn.weatherapi.com/weather/64x64/day/116.png',
              'code' => 1000 + (address.to_s.sum + day_offset) % 30
            },
            'uv' => 4
          },
          'astro' => {
            'sunrise' => '06:30 AM',
            'sunset' => '07:45 PM',
            'moonrise' => '10:42 PM',
            'moonset' => '09:24 AM',
            'moon_phase' => 'Waxing Gibbous',
            'moon_illumination' => '78'
          },
          'hour' => (0..23).map do |hour|
            hour_temp_variation = Math.sin(hour / 24.0 * Math::PI) * 5
            {
              'time_epoch' => (date.to_time + hour.hours).to_i,
              'time' => (date.to_time + hour.hours).strftime('%Y-%m-%d %H:%M'),
              'temp_c' => (base_temp + hour_temp_variation).round(1),
              'temp_f' => ((base_temp + hour_temp_variation) * 9 / 5 + 32).round(1),
              'condition' => {
                'text' => mock_hour_condition(hour, address),
                'icon' => '//cdn.weatherapi.com/weather/64x64/day/116.png',
                'code' => 1000 + (address.to_s.sum + hour) % 30
              },
              'wind_mph' => 6 + (hour % 12),
              'wind_kph' => 10 + (hour % 20),
              'wind_dir' => %w[N NE E SE S SW W NW][hour % 8],
              'humidity' => 40 + (hour % 40),
              'cloud' => (hour % 100),
              'feelslike_c' => (base_temp + hour_temp_variation - 2).round(1),
              'feelslike_f' => ((base_temp + hour_temp_variation - 2) * 9 / 5 + 32).round(1),
              'chance_of_rain' => ((address.to_s.sum + hour) % 50),
              'chance_of_snow' => ((address.to_s.sum + hour) % 10)
            }
          end
        }
      end
    }
  end
  
  def mock_location(address)
    {
      'name' => extract_city(address),
      'region' => extract_region(address),
      'country' => 'United States of America',
      'lat' => 34.0 + (address.to_s.sum % 10),
      'lon' => -118.0 - (address.to_s.sum % 10),
      'tz_id' => 'America/Los_Angeles',
      'localtime_epoch' => Time.now.to_i,
      'localtime' => Time.now.strftime('%Y-%m-%d %H:%M')
    }
  end
  
  def extract_city(address)
    if address.to_s.include?(',')
      address.to_s.split(',').first.strip.capitalize
    else
      address.to_s.strip.capitalize
    end
  end
  
  def extract_region(address)
    if address.to_s.include?(',')
      address.to_s.split(',').last.strip.upcase
    else
      'CA'
    end
  end
  
  def mock_condition_text(address)
    conditions = ['Sunny', 'Partly cloudy', 'Cloudy', 'Overcast', 
                 'Mist', 'Patchy rain possible', 'Light rain', 'Rain',
                 'Moderate rain', 'Heavy rain', 'Clear']
    conditions[address.to_s.sum % conditions.length]
  end
  
  def mock_day_condition(day_offset, address)
    conditions = ['Sunny', 'Partly cloudy', 'Cloudy', 'Overcast', 
                 'Patchy rain possible', 'Light rain', 'Moderate rain']
    conditions[(address.to_s.sum + day_offset) % conditions.length]
  end
  
  def mock_hour_condition(hour, address)
    night_conditions = ['Clear', 'Partly cloudy', 'Cloudy', 'Overcast', 
                       'Patchy rain possible', 'Light rain shower']
    day_conditions = ['Sunny', 'Partly cloudy', 'Cloudy', 'Overcast', 
                     'Patchy rain possible', 'Light rain']
    
    if hour >= 6 && hour <= 18
      day_conditions[(address.to_s.sum + hour) % day_conditions.length]
    else
      night_conditions[(address.to_s.sum + hour) % night_conditions.length]
    end
  end
end
