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
  # @param forecast_list [Array] List of forecast periods from API
  # @return [Array] Array of daily forecast hashes
  def get_forecast_days(forecast_list)
    return [] if forecast_list.blank?
    
    # Handle WeatherAPI.com format (forecastday array)
    if forecast_list.first.is_a?(Hash) && forecast_list.first['date']
      # WeatherAPI.com format - forecast > forecastday > condition
      return forecast_list.map do |day|
        {
          date: Date.parse(day['date']),
          high_temp: day.dig('day', 'maxtemp_c'),
          low_temp: day.dig('day', 'mintemp_c'),
          # Pass the complete condition object with icon and text
          condition: day.dig('day', 'condition'),
          temps: [day.dig('day', 'avgtemp_c')]
        }
      end
    end
    
    # Original OpenWeatherMap format handling
    days = {}
    
    forecast_list.each do |item|
      # Skip if dt is nil to avoid errors
      next unless item['dt'].present?
      
      date = Time.at(item['dt']).to_date
      day_key = date.to_s
      
      if !days[day_key]
        days[day_key] = {
          date: date,
          high_temp: item.dig('main', 'temp_max'),
          low_temp: item.dig('main', 'temp_min'),
          condition: item.dig('weather', 0),
          temps: [item.dig('main', 'temp')]
        }
      else
        day = days[day_key]
        max_temp = item.dig('main', 'temp_max')
        min_temp = item.dig('main', 'temp_min')
        temp = item.dig('main', 'temp')
        
        day[:high_temp] = [day[:high_temp], max_temp].compact.max if max_temp
        day[:low_temp] = [day[:low_temp], min_temp].compact.min if min_temp
        day[:temps] << temp if temp
      end
    end
    
    days.values
  end
  
  # Format temperature for display
  # @param temp [Float] Temperature value
  # @param units [String] 'imperial' or 'metric'
  # @return [String] Formatted temperature with unit
  def format_temp(temp, units)
    # Convert to Fahrenheit for imperial units since API returns Celsius
    if units == 'imperial'
      converted_temp = (temp * 9.0/5.0) + 32
      return "#{converted_temp.round}°F"
    end
    
    # Return Celsius for metric units
    "#{temp.round}°C"
  end
  
  private
  
  def format_single_condition(condition)
    condition.to_s.split.map(&:capitalize).join(" ")
  end
end
