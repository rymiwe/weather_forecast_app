# frozen_string_literal: true

# Service for parsing forecast data
class ForecastParserService
  # Parse the extended forecast JSON data
  # @param extended_forecast [String] JSON string of extended forecast data
  # @return [Hash, nil] Parsed JSON or nil if parsing fails
  def self.parse(extended_forecast)
    return nil unless extended_forecast.present?
    
    JSON.parse(extended_forecast)
  rescue JSON::ParserError
    Rails.logger.error "Failed to parse extended forecast JSON"
    nil
  end
  
  # Extract daily forecasts from parsed forecast data
  # @param parsed_data [Hash] Parsed forecast data
  # @return [Array] Array of daily forecast data
  def self.extract_daily_forecasts(parsed_data)
    # Handle WeatherAPI.com structure
    if parsed_data&.dig('forecast', 'forecastday').present?
      return parsed_data['forecast']['forecastday']
    # Handle OpenWeatherMap structure
    elsif parsed_data&.dig('forecast', 'list').present?
      return parsed_data['forecast']['list']
    end
    
    []
  rescue StandardError => e
    Rails.logger.error "Error extracting daily forecasts: #{e.message}"
    []
  end
  
  # Extract current weather from parsed forecast data
  # @param parsed_data [Hash] Parsed forecast data
  # @return [Hash] Current weather data
  def self.extract_current_weather(parsed_data)
    return {} unless parsed_data&.dig('current').present?
    
    parsed_data['current']
  rescue StandardError => e
    Rails.logger.error "Error extracting current weather: #{e.message}"
    {}
  end
end
