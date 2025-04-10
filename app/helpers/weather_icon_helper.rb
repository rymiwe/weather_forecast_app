# frozen_string_literal: true

# Helper for displaying weather icons
module WeatherIconHelper
  # Map weather conditions to standardized icon names
  # @param condition [String] The weather condition description
  # @return [String] The standardized icon name for the weather_icon partial
  def weather_icon_name(condition)
    return 'partly_cloudy' if condition.blank?
    
    condition = condition.to_s.downcase.strip
    
    case condition
    when /sunny/, /sun/, /clear/
      'sunny'
    when /cloud/, /overcast/, /partly/
      'cloudy'
    when /rain/, /shower/, /drizzle/
      'rain'
    when /snow/, /sleet/, /winter/
      'snow'
    when /storm/, /thunder/
      'thunderstorm'
    when /fog/, /mist/, /haze/
      'fog'
    else
      Rails.logger.debug "Defaulting condition [#{condition}] to partly_cloudy"
      'partly_cloudy' # Default fallback
    end
  end
end
