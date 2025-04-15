# frozen_string_literal: true

module ForecastsHelper
  # Format weather condition strings consistently
  # Takes a condition string or array of strings and returns properly formatted condition(s)
  def format_conditions(conditions)
    return "" if conditions.blank?
    
    if conditions.is_a?(Array)
      conditions.map { |condition| format_single_condition(condition) }.join(", ")
    else
      format_single_condition(conditions)
    end
  end
  
  # Process forecast list data into daily forecasts
  # @param forecast_list [Array, String] List of forecast periods from API or JSON string
  # @param timezone [String] Timezone ID from the API
  # @param use_imperial [Boolean] Whether to use imperial units
  # @return [Array] Array of daily forecast hashes
  def get_forecast_days(forecast_list, timezone = nil, use_imperial = false)
    return [] if forecast_list.blank?
    
    # Parse JSON string if needed
    if forecast_list.is_a?(String)
      begin
        forecast_list = JSON.parse(forecast_list)
      rescue JSON::ParserError => e
        Rails.logger.error("Failed to parse forecast JSON: #{e.message}")
        return []
      end
    end
    
    if weather_api_format?(forecast_list)
      process_weather_api_forecast(forecast_list, use_imperial)
    else
      process_open_weather_map_forecast(forecast_list)
    end
  end
  
  # Format temperature for display
  # @param temp [Float] Temperature value
  # @param units [String] Units to display ('imperial' or 'metric')
  # @return [String] Formatted temperature with units
  def format_temp(temp, units)
    return "" if temp.blank?
    
    unit_symbol = units == 'imperial' ? "°F" : "°C"
    "#{temp.round}#{unit_symbol}"
  end
  
  # Display temperature with the appropriate unit
  # @param temp_c [Float] Celsius value
  # @param temp_f [Float] Fahrenheit value
  # @param use_imperial [Boolean] Whether to use imperial units
  # @return [String] Formatted temperature with units
  def display_temperature(temp_c, temp_f, use_imperial = false)
    return "" if temp_c.blank? && temp_f.blank?
    if use_imperial
      return "" if temp_f.blank?
      "#{temp_f.round}°F"
    else
      return "" if temp_c.blank?
      "#{temp_c.round}°C"
    end
  end
  
  # Determines if imperial units should be used
  # @return [Boolean] true if imperial units should be used, false for metric
  def use_imperial?
    # Check if a forecast instance is available
    return @forecast.should_use_imperial? if @forecast&.respond_to?(:should_use_imperial?)
    
    # Default to imperial for US users
    request_ip = request.remote_ip if defined?(request) && request.present?
    country_code = determine_country_from_ip(request_ip)
    ['US', 'USA'].include?(country_code)
  end
  
  private
  
  def format_single_condition(condition)
    condition.to_s.split.map(&:capitalize).join(" ")
  end
  
  def weather_api_format?(forecast_list)
    # This could be the root forecast object from WeatherAPI
    return true if forecast_list.is_a?(Hash) && forecast_list['forecast'] && forecast_list['forecast']['forecastday'].is_a?(Array)
    
    # Or it could be the forecastday array directly
    if forecast_list.is_a?(Array) && forecast_list.first.is_a?(Hash)
      return true if forecast_list.first['date'].present?
    end
    
    false
  end
  
  def process_weather_api_forecast(forecast_list, use_imperial)
    # Handle different formats of WeatherAPI.com data
    if forecast_list.is_a?(Hash) && forecast_list['forecast'] && forecast_list['forecast']['forecastday'].is_a?(Array)
      # Full API response format
      forecast_days = forecast_list['forecast']['forecastday']
    else
      # Just the forecastday array
      forecast_days = forecast_list
    end
    
    forecast_days.map do |day|
      {
        date: day['date'].is_a?(String) ? Date.parse(day['date']) : day['date'],
        day_name: day['date'].is_a?(String) ? Date.parse(day['date']).strftime('%A') : day['date'].strftime('%A'),
        high_c: day['day']['maxtemp_c'],
        high_f: day['day']['maxtemp_f'],
        low_c: day['day']['mintemp_c'],
        low_f: day['day']['mintemp_f'],
        condition: day['day']['condition']
      }
    end
  end
  
  def process_open_weather_map_forecast(forecast_list)
    # Legacy method for processing OpenWeatherMap format
    # This is maintained for backward compatibility
    forecast_list
  end
  
  # Convert Celsius to Fahrenheit
  def celsius_to_fahrenheit(celsius)
    return nil if celsius.nil?
    (celsius.to_f * 9 / 5) + 32
  end
  
  # Determine country code from IP address
  # This is a simplified method for demo purposes
  def determine_country_from_ip(ip)
    return 'US' unless defined?(Geocoder)
    
    begin
      location = Geocoder.search(ip).first
      location&.country_code || 'US'
    rescue => e
      Rails.logger.error "Error in geocoding IP: #{e.message}"
      'US' # Default to US
    end
  end
end
