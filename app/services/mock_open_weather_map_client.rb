# frozen_string_literal: true
require 'singleton'

# A mock implementation of the OpenWeatherMapClient for testing and development
class MockOpenWeatherMapClient
  include Singleton
  
  attr_accessor :mock_condition
  
  # Initialize with default values
  def initialize
    # No API key needed for mock
    @mock_condition = nil
  end
  
  # Mock implementation of get_coordinates that returns the same coordinates for any address
  # @param address [String] Address to geocode
  # @return [Hash] Mock coordinates
  def get_coordinates(address:)
    # Determine if the address is for a US location for testing
    is_us = address.to_s.match?(/usa|us$|united states|america|san francisco|new york|chicago|miami|portland|seattle|boston|texas|california|washington|oregon|florida/i)
    
    # Use specific coordinates based on the address to simulate different locations
    lat = is_us ? 37.7749 : 51.5074 
    lon = is_us ? -122.4194 : -0.1278
    
    { "lat" => lat, "lon" => lon }
  end
  
  # Mock implementation of get_weather
  # @param address [String] Address to get weather for
  # @return [Hash] Mock weather data (always in metric/Celsius)
  def get_weather(address:)
    Rails.logger.debug "MockOpenWeatherMapClient: get_weather called for address: #{address}"
    
    # Determine if this is a US address for testing different units
    coordinates = get_coordinates(address: address)
    Rails.logger.debug "MockOpenWeatherMapClient: Coordinates: #{coordinates.inspect}"
    
    is_us = coordinates["lat"] == 37.7749
    
    # Generate mock data
    current_weather = mock_current_weather(is_us)
    Rails.logger.debug "MockOpenWeatherMapClient: Generated current_weather: #{current_weather ? 'Success' : 'Nil'}"
    
    forecast = mock_forecast(is_us)
    Rails.logger.debug "MockOpenWeatherMapClient: Generated forecast: #{forecast ? 'Success' : 'Nil'}"
    
    result = {
      current_weather: current_weather,
      forecast: forecast
    }
    
    Rails.logger.debug "MockOpenWeatherMapClient: Final result: #{result ? 'Success' : 'Nil'}"
    result
  end
  
  # Mock current weather data
  # @param is_us [Boolean] Whether this is a US location
  # @return [Hash] Mock current weather data
  def mock_current_weather(is_us)
    # US location gets sunny weather, non-US gets cloudy
    condition = @mock_condition || (is_us ? "clear sky" : "scattered clouds")
    
    # Temperature values are always stored in the requested units
    # This ensures we test location-based unit display correctly
    {
      "coord" => {
        "lon" => is_us ? -122.4194 : -0.1278,
        "lat" => is_us ? 37.7749 : 51.5074
      },
      "weather" => [
        {
          "id" => is_us ? 800 : 803,
          "main" => is_us ? "Clear" : "Clouds",
          "description" => condition,
          "icon" => is_us ? "01d" : "04d"
        }
      ],
      "main" => {
        "temp" => is_us ? 20 : 15,
        "feels_like" => is_us ? 18 : 13,
        "temp_min" => is_us ? 18 : 12,
        "temp_max" => is_us ? 22 : 17,
        "pressure" => 1015,
        "humidity" => 72
      },
      "wind" => {
        "speed" => 3.6,
        "deg" => 320
      },
      "sys" => {
        "country" => is_us ? "US" : "GB"
      },
      "name" => is_us ? "San Francisco" : "London",
      "dt" => Time.now.to_i
    }
  end
  
  private
  
  # Check if an address is in the United States
  # @param address [String] The address to check
  # @return [Boolean] True if address appears to be in the US
  def us_address?(address)
    return false if address.blank?
    
    address = address.downcase
    address.include?('usa') || 
      address.include?('united states') || 
      address.end_with?('us') ||
      address.match(/\b[a-z]{2}\s+\d{5}(-\d{4})?\b/) || # US zip code pattern
      address.match(/\b(AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY)\b/i)
  end
  
  # Generate mock forecast data
  # @param is_us [Boolean] Whether location is in the US
  # @return [Hash] Mock forecast data
  def mock_forecast(is_us)
    # Generate a list of mock forecast periods
    list = []
    
    # Generate 5 days of forecast data
    5.times do |i|
      # US locations get a variety of weather, non-US gets consistent weather
      conditions = if is_us
        case i % 5
        when 0 then "clear sky"
        when 1 then "few clouds"
        when 2 then "scattered showers"
        when 3 then "light rain"
        when 4 then "sunny"
        end
      else
        ["overcast clouds", "light rain", "broken clouds"].sample
      end
      
      # Create the forecast entry
      date_timestamp = Time.now.beginning_of_day.advance(days: i + 1).to_i
      
      # Calculate temperatures (different for US/non-US and metric/imperial)
      base_temp = is_us ? 22 : 14
      temp_offset = i - 2 # -2, -1, 0, 1, 2
      
      # Add forecast entry for morning, noon, and evening of each day
      [9, 12, 18].each do |hour|
        entry_timestamp = Time.at(date_timestamp).advance(hours: hour).to_i
        
        list << {
          "dt" => entry_timestamp,
          "main" => {
            "temp" => base_temp + temp_offset,
            "temp_min" => base_temp + temp_offset - 2,
            "temp_max" => base_temp + temp_offset + 2,
            "feels_like" => base_temp + temp_offset - 1
          },
          "weather" => [
            {
              "main" => conditions.split.map(&:capitalize).join(" "),
              "description" => conditions
            }
          ]
        }
      end
    end
    
    { "list" => list }
  end
end
