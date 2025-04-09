# frozen_string_literal: true

# Service for determining temperature units based on user preference, config, or IP
# Follows enterprise best practices by isolating this concern
class TemperatureUnitsService
  # Determine temperature units preference
  # @param session [Hash] The user's session data
  # @param ip_address [String] The user's IP address
  # @return [String] 'imperial' or 'metric'
  def self.determine_units(session: nil, ip_address: nil)
    # Priority: User preference > Environment setting > IP-based detection
    session_preference = session && session[:temperature_units]
    
    session_preference || 
      config_default || 
      ip_based_units(ip_address)
  end
  
  private_class_method
  
  # Get configured default units
  # @return [String] Default units from configuration
  def self.config_default
    Rails.configuration.x.weather.default_unit
  end
  
  # Get units based on IP address
  # @param ip_address [String] The user's IP address
  # @return [String] 'imperial' or 'metric' based on location
  def self.ip_based_units(ip_address)
    return 'imperial' unless ip_address.present?
    UserLocationService.units_for_ip(ip_address)
  end
end
