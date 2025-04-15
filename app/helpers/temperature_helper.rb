# frozen_string_literal: true
require 'ruby-units'

# Helper for displaying temperature values consistently throughout the application
# Follows DRY principles by centralizing temperature formatting logic
module TemperatureHelper
  # Display a temperature value with the appropriate unit
  # @param temp_c [Float] Temperature value in Celsius
  # @param temp_f [Float] Temperature value in Fahrenheit
  # @param use_imperial [Boolean] Whether to use imperial units
  # @param options [Hash] Display options
  # @option options [Boolean] :show_unit Whether to show the unit symbol
  # @option options [String] :size Size of the temperature text ('sm', 'md', 'lg', 'xl', '2xl')
  # @return [String] Formatted temperature string
  def display_temperature(temp_c, temp_f, use_imperial = false, options = {})
    return "N/A" if temp_c.nil? && temp_f.nil?

    # Default options
    options = {
      show_unit: true,
      size: nil
    }.merge(options || {})

    value = use_imperial ? temp_f : temp_c
    unit_symbol = use_imperial ? "°F" : "°C"
    return "N/A" if value.nil?

    temp_str = value.round.to_s
    temp_str += unit_symbol if options[:show_unit]

    if options[:size]
      css_class = size_class_for(options[:size])
      temp_str = content_tag(:span, temp_str, class: css_class) if css_class.present?
    end

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
