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
    days = {}
    
    forecast_list.each do |item|
      date = Time.at(item['dt']).to_date
      day_key = date.to_s
      
      if !days[day_key]
        days[day_key] = {
          date: date,
          high_temp: item['main']['temp_max'],
          low_temp: item['main']['temp_min'],
          condition: item['weather'][0]['description'],
          temps: [item['main']['temp']]
        }
      else
        day = days[day_key]
        day[:high_temp] = [day[:high_temp], item['main']['temp_max']].max
        day[:low_temp] = [day[:low_temp], item['main']['temp_min']].min
        day[:temps] << item['main']['temp']
      end
    end
    
    days.values
  end
  
  # Format temperature for display
  # @param temp [Float] Temperature value
  # @param units [String] 'imperial' or 'metric'
  # @return [String] Formatted temperature with unit
  def format_temp(temp, units)
    if units == 'imperial'
      "#{((temp * 9.0/5.0) + 32).round}°F"
    else
      "#{temp.round}°C"
    end
  end
  
  private
  
  def format_single_condition(condition)
    condition.to_s.split.map(&:capitalize).join(" ")
  end
end
