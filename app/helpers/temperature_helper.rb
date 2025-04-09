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
  # @return [String] Formatted temperature string
  def display_temperature(temperature, user_preference = session[:temperature_units], options = {})
    return "N/A" unless temperature.present?
    
    precision = options.fetch(:precision, 0)
    show_unit = options.fetch(:show_unit, true)
    size_class = size_class_for(options.fetch(:size, nil))
    
    # Ensure we have a numeric value - but we now expect integer in the database
    temperature = temperature.to_i
    
    # Convert if user prefers imperial (our database stores everything in Celsius as integers)
    displayed_temp = if user_preference.to_s == 'imperial'
                       TemperatureConversionService.celsius_to_fahrenheit(temperature)
                     else
                       temperature
                     end
    
    unit_symbol = if show_unit
                    user_preference.to_s == 'imperial' ? '°F' : '°C'
                  else
                    ''
                  end
    
    # No need for rounding decimals anymore since we're using integers
    temp_value = displayed_temp
    
    # Add CSS class for styling if size is specified
    if size_class.present?
      content_tag(:span, class: size_class) do
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
      'text-xl font-bold'
    when 'xl'
      'text-3xl font-bold'
    when '2xl'
      'text-5xl font-bold'
    else
      ''
    end
  end
end
