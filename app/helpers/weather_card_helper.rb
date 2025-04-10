# frozen_string_literal: true

# Helper for weather card styling in the forecast views
module WeatherCardHelper
  # Determine the appropriate background color class for a forecast day card
  # @param condition [String] Weather condition (e.g., 'rain', 'sunny')
  # @param high_temp [Integer] High temperature for the day
  # @param units [String] Temperature units ('metric' or 'imperial')
  # @return [String] CSS class for the card background
  def forecast_card_background_class(condition, high_temp, units = 'metric')
    return 'bg-gray-50' if condition.blank?
    
    condition = condition.to_s.downcase
    high_temp = high_temp.to_i
    
    # Log the input params for debugging
    Rails.logger.debug "forecast_card_background_class called with: condition=#{condition}, high_temp=#{high_temp}, units=#{units}"
    
    # Check condition first
    if condition.include?('rain') || condition.include?('shower') || condition == 'rainy'
      'bg-blue-100'
    elsif condition.include?('snow') || condition.include?('sleet')
      'bg-blue-50'
    elsif condition.include?('cloud')
      'bg-gray-100'
    elsif condition.include?('storm') || condition.include?('thunder')
      'bg-slate-200'
    elsif condition == 'sunny' || condition.include?('sun') || condition.include?('clear')
      'bg-yellow-100'
    # Temperature-based backgrounds
    elsif units == 'imperial'
      # Imperial temperature thresholds
      if high_temp > 86 # Hot day
        'bg-orange-50'
      elsif high_temp < 50 # Cold day
        'bg-indigo-50'
      else
        'bg-green-50' # Default to light green for moderate temps
      end
    else
      # Metric temperature thresholds
      if high_temp > 30 # Hot day
        'bg-orange-50'
      elsif high_temp < 10 # Cold day
        'bg-indigo-50'
      else
        'bg-green-50' # Default to light green for moderate temps
      end
    end
  end
end
