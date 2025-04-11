# frozen_string_literal: true

# Service for determining temperature display units based on user preference or location
# Follows enterprise best practices by isolating this concern
class TemperatureUnitsService
  # Determine the appropriate temperature units for display
  # @param session [Hash] User's session with potential temperature_units key
  # @return [String] Temperature units to use ('metric' or 'imperial')
  def self.determine_units(session: nil, ip_address: nil)
    # Priority 1: Check session preference if available (user explicitly set)
    if session.present? && session[:temperature_units].present?
      session_pref = session[:temperature_units].to_s.downcase
      return valid_units_or_default(session_pref)
    end
    
    # When no preference is set, default to metric (most of the world uses it)
    'metric'
  end
  
  private
  
  # Ensure the units value is one of the valid options
  # @param units [String] The units string to validate
  # @return [String] Valid units or 'metric' as default
  def self.valid_units_or_default(units)
    valid_units = ['metric', 'imperial']
    valid_units.include?(units) ? units : 'metric'
  end
end
