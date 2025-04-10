# frozen_string_literal: true

# Helper for displaying temperature values consistently throughout the application
# Follows DRY principles by centralizing temperature formatting logic
module TemperatureHelper
  # Format a temperature for display with proper units
  # @param temperature [Integer] The temperature value in Celsius
  # @param user_preference [String] The user's unit preference ('metric' or 'imperial')
  # @param options [Hash] Additional options for formatting
  # @option options [Integer] :precision Number of decimal places (default: 0)
  # @option options [Boolean] :show_unit Whether to show the unit symbol (default: true)
  # @option options [String] :size CSS size class ('sm', 'md', 'lg' - default: nil)
  # @option options [Boolean] :colorize Whether to apply temperature-based colors (default: true)
  # @return [String] Formatted temperature string
  def display_temperature(temperature, user_preference = session[:temperature_units], options = {})
    return "N/A" unless temperature.present?
    
    # Handle nil options
    options ||= {}
    
    precision = options.fetch(:precision, 0)
    show_unit = options.fetch(:show_unit, true)
    size_class = size_class_for(options.fetch(:size, nil))
    colorize = options.fetch(:colorize, true)
    
    # Ensure we have a numeric value - but we now expect integer in the database
    temperature = temperature.to_i
    
    # Use user_preference if provided, otherwise fall back to session
    actual_preference = user_preference.presence || session[:temperature_units]
    
    # Convert if user prefers imperial (our database stores everything in Celsius as integers)
    displayed_temp = if actual_preference.to_s == 'imperial'
                       TemperatureConversionService.celsius_to_fahrenheit(temperature)
                     else
                       temperature
                     end
    
    unit_symbol = if show_unit
                    actual_preference.to_s == 'imperial' ? '°F' : '°C'
                  else
                    ''
                  end
    
    # No need for rounding decimals anymore since we're using integers
    temp_value = displayed_temp
    
    # Determine temperature color class based on value and units
    color_class = colorize ? temperature_color_class(displayed_temp, actual_preference.to_s) : nil
    
    # Combine classes if both size and color are specified
    css_classes = [size_class, color_class].reject(&:blank?).join(' ')
    
    # Add CSS class for styling if any classes are specified
    if css_classes.present?
      content_tag(:span, class: css_classes) do
        "#{temp_value}#{unit_symbol}".html_safe
      end
    else
      "#{temp_value}#{unit_symbol}".html_safe
    end
  end
  
  private
  
  # Return CSS class based on requested size
  def size_class_for(size)
    case size
    when 'sm'
      'text-sm'
    when 'md'
      'text-base'
    when 'lg'
      'text-lg'
    when 'xl'
      'text-3xl font-bold'
    when '2xl'
      'text-5xl font-bold'
    else
      ''
    end
  end
  
  # Return appropriate color class based on temperature value and units
  def temperature_color_class(temp, units)
    # Temperature thresholds are different for Celsius and Fahrenheit
    if units == 'imperial'
      if temp < 32  # Freezing point in Fahrenheit
        'text-blue-500'
      elsif temp >= 86 # Hot in Fahrenheit (30°C ≈ 86°F)
        'text-red-500'
      else
        'text-gray-700'
      end
    else # metric/celsius
      if temp <= 0  # Freezing point in Celsius
        'text-blue-500'
      elsif temp >= 30 # Hot in Celsius
        'text-red-500'
      else
        'text-gray-700'
      end
    end
  end
end
