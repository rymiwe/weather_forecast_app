# frozen_string_literal: true
require 'ruby-units'

# Helper for displaying temperature values consistently throughout the application
# Follows DRY principles by centralizing temperature formatting logic
module TemperatureHelper
  # Display a temperature value with the appropriate unit
  # @param temp [Float] Temperature value in Celsius (always stored in metric)
  # @param units [String] Units to display in ('metric' or 'imperial')
  # @param options [Hash] Display options
  # @option options [Boolean] :show_unit Whether to show the unit symbol
  # @option options [String] :size Size of the temperature text ('sm', 'md', 'lg', 'xl', '2xl')
  # @return [String] Formatted temperature string
  def display_temperature(temp, units = nil, options = {})
    return "N/A" if temp.nil?
    
    # Default options
    options = {
      show_unit: true,
      size: nil
    }.merge(options || {})
    
    # Get units from helper if not explicitly provided
    units = get_temperature_units(units)
    
    # Convert temperature if needed
    if units == 'imperial'
      # Convert Celsius to Fahrenheit using ruby-units
      converted_temp = Unit.new("#{temp} tempC").convert_to('tempF').scalar.round
      unit_symbol = "°F"
    else
      # Keep as Celsius
      converted_temp = temp.round
      unit_symbol = "°C"
    end
    
    # Format the temperature string
    temp_str = converted_temp.to_s
    temp_str += unit_symbol if options[:show_unit]
    
    # Apply CSS class for size if specified
    if options[:size]
      css_class = size_class_for(options[:size])
      temp_str = content_tag(:span, temp_str, class: css_class) if css_class.present?
    end
    
    # Return the formatted string
    temp_str.html_safe
  end
  
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
  
  # Get the temperature units from the session, controller, or default to metric
  # @param controller_units [String] Units set in the controller
  # @return [String] 'metric' or 'imperial'
  def get_temperature_units(controller_units = nil)
    # Use units from controller param if provided
    return controller_units if controller_units.present?
    
    # Otherwise check session
    if defined?(session) && session[:temperature_units].present?
      return session[:temperature_units]
    end
    
    # Default to metric if no preference is set
    'metric'
  end
end
