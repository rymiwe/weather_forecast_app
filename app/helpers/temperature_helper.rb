# frozen_string_literal: true

# Helper for displaying temperature values consistently throughout the application
# Follows DRY principles by centralizing temperature formatting logic
module TemperatureHelper
  # Format a temperature for display
  # @param temp [Integer] Temperature value to display
  # @param units [String] Temperature units ('metric' for Celsius, 'imperial' for Fahrenheit)
  # @param options [Hash] Additional options
  # @option options [String] :size Size of the temperature text ('sm', 'md', 'lg', 'xl', '2xl')
  # @option options [Boolean] :colorize Whether to colorize the temperature based on value
  # @return [String] HTML for displaying the temperature
  def display_temperature(temp, units, options = {})
    return "N/A" if temp.nil?
    
    # Determine units from session if not specified
    units ||= session[:temperature_units] || Rails.configuration.x.weather.default_unit
    
    # Calculate the temperature value in the requested units
    value = if units.to_s.downcase == 'imperial'
      # Convert from Celsius to Fahrenheit
      (temp.to_f * 9/5 + 32).round
    else
      # Keep as Celsius
      temp.to_i
    end
    
    # Default options
    options = { size: nil, colorize: true }.merge(options || {})
    
    # Apply size class if specified
    css_classes = []
    if options[:size]
      css_classes << size_class_for(options[:size])
    end
    
    # Apply color based on temperature unless colorize is false
    if options[:colorize]
      css_classes << temperature_color_class(value, units)
    end
    
    # Format with the degree symbol and unit
    css_class = css_classes.join(' ')
    unit_symbol = units.to_s.downcase == 'imperial' ? 'F' : 'C'
    
    if css_class.present?
      "<span class=\"#{css_class}\">#{value}&#176;#{unit_symbol}</span>".html_safe
    else
      "#{value}&#176;#{unit_symbol}".html_safe
    end
  end
  
  # Return appropriate background gradient class based on temperature and conditions
  # @param temp [Integer] Temperature value
  # @param units [String] Temperature units ('metric' or 'imperial')
  # @param conditions [String] Weather conditions (e.g., 'rain', 'snow')
  # @return [String] CSS class for background gradient
  def temperature_background_class(temp, units, conditions = nil)
    # Default to weather condition-based backgrounds first
    if conditions.present?
      conditions = conditions.to_s.downcase
      
      if conditions.include?('rain') || conditions.include?('shower') || conditions.include?('drizzle')
        return 'bg-gradient-to-r from-blue-600 to-blue-700'
      elsif conditions.include?('snow') || conditions.include?('sleet') || conditions.include?('winter')
        return 'bg-gradient-to-r from-blue-300 to-blue-400'
      elsif conditions.include?('storm') || conditions.include?('thunder')
        return 'bg-gradient-to-r from-slate-700 to-slate-800'
      elsif conditions.include?('fog') || conditions.include?('mist') || conditions.include?('haze')
        return 'bg-gradient-to-r from-gray-400 to-gray-500'
      elsif conditions.include?('cloud')
        return 'bg-gradient-to-r from-gray-500 to-blue-500'
      end
    end
    
    # If no condition match or no conditions provided, use temperature-based gradient
    if units == 'imperial'
      if temp < 32  # Freezing in Fahrenheit
        'bg-gradient-to-r from-blue-500 to-indigo-600'
      elsif temp < 50  # Cold in Fahrenheit
        'bg-gradient-to-r from-blue-400 to-blue-500'
      elsif temp < 68  # Mild in Fahrenheit
        'bg-gradient-to-r from-green-500 to-teal-600'
      elsif temp < 86  # Warm in Fahrenheit
        'bg-gradient-to-r from-yellow-500 to-amber-600'
      else  # Hot in Fahrenheit
        'bg-gradient-to-r from-orange-500 to-red-600'
      end
    else # Celsius
      if temp <= 0  # Freezing in Celsius
        'bg-gradient-to-r from-blue-500 to-indigo-600'
      elsif temp < 10  # Cold in Celsius
        'bg-gradient-to-r from-blue-400 to-blue-500'
      elsif temp < 20  # Mild in Celsius
        'bg-gradient-to-r from-green-500 to-teal-600'
      elsif temp < 30  # Warm in Celsius
        'bg-gradient-to-r from-yellow-500 to-amber-600'
      else  # Hot in Celsius
        'bg-gradient-to-r from-orange-500 to-red-600'
      end
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
