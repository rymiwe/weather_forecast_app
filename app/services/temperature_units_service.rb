# frozen_string_literal: true

# Service for determining temperature units based on user preference, config, or IP
# Follows enterprise best practices by isolating this concern
class TemperatureUnitsService
  # Determine the appropriate temperature units based on available information
  # @param session [Hash] User's session with potential temperature_units key
  # @param ip_address [String] User's IP address for location-based detection
  # @return [String] Temperature units to use ('metric' or 'imperial')
  def self.determine_units(session: nil, ip_address: nil)
    # Priority 1: Check session preference if available
    if session.present? && session[:temperature_units].present?
      session_pref = session[:temperature_units].to_s.downcase
      return valid_units_or_default(session_pref)
    end
    
    # Priority 2: Check app configuration default
    config_default = Rails.configuration.x.weather.default_unit
    return config_default if config_default.present?
    
    # Priority 3: Use IP-based detection if available
    if ip_address.present?
      begin
        ip_units = UserLocationService.units_for_ip(ip_address)
        return ip_units if ip_units.present?
      rescue StandardError => e
        Rails.logger.error "IP-based unit detection error: #{e.message}"
        # Fall through to default on error
      end
    end
    
    # Final fallback: Use imperial as default
    'imperial'
  end
  
  private
  
  # Ensure the units value is one of the valid options
  # @param units [String] The units string to validate
  # @return [String] Valid units or 'imperial' as default
  def self.valid_units_or_default(units)
    valid_units = ['metric', 'imperial']
    valid_units.include?(units) ? units : 'imperial'
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
