# frozen_string_literal: true

# Helper to provide weather condition icons
module WeatherIconsHelper
  # Returns the appropriate weather icon name based on the condition
  # @param condition [String] Weather condition description
  # @return [String] Icon name corresponding to the condition
  def weather_icon_name(condition)
    return 'partly_cloudy' if condition.blank?

    case condition.to_s.downcase
    when /sunny|clear|sun/
      'sunny'
    when /cloud|overcast/
      'cloudy'
    when /rain|drizzle|shower/
      'rainy'
    when /thunder|storm|lightning/
      'stormy'
    when /snow|sleet|blizzard|flurry/
      'snowy'
    when /fog|mist|haze/
      'foggy'
    when /wind|gust|breez/
      'windy'
    else
      'partly_cloudy' # Default fallback
    end
  end

  # Renders a weather icon with appropriate classes
  # @param condition [String] Weather condition description
  # @param classes [String] CSS classes to apply to the icon
  # @return [String] HTML for the weather icon
  def weather_icon(condition, classes = "h-8 w-8")
    render partial: 'shared/weather_icon', locals: {
      icon_name: weather_icon_name(condition),
      css_classes: classes
    }
  end
end
