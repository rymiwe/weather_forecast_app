# frozen_string_literal: true

# Service to determine user location and preferences based on IP address
class UserLocationService
  # Countries that use imperial (Fahrenheit) temperature units
  IMPERIAL_UNIT_COUNTRIES = %w[US LR MM].freeze # USA, Liberia, Myanmar
  
  # Default unit when country cannot be determined
  DEFAULT_UNIT = 'metric'

  # Determine appropriate temperature units based on IP address
  # Returns 'imperial' for US, Liberia, Myanmar, 'metric' for all other countries
  # Falls back to DEFAULT_UNIT if location cannot be determined (e.g., local/private IPs)
  #
  # @param ip_address [String] IP address to geolocate
  # @return [String] 'imperial' or 'metric'
  def self.units_for_ip(ip_address)
    return DEFAULT_UNIT if ip_address.blank? || local_ip?(ip_address)
    
    begin
      # Use geocoder to get country code from IP
      location = Geocoder.search(ip_address).first
      country_code = location&.country_code
      
      # Return imperial for specific countries, metric for all others
      IMPERIAL_UNIT_COUNTRIES.include?(country_code) ? 'imperial' : 'metric'
    rescue => e
      Rails.logger.error("Error determining location from IP: #{e.message}")
      DEFAULT_UNIT
    end
  end
  
  # Detect if the IP is a local/private address (no geolocation possible)
  # @param ip_address [String] IP address to check
  # @return [Boolean] true if the IP is local/private
  def self.local_ip?(ip_address)
    return true if ip_address.blank?
    
    # Check common private IP patterns
    private_patterns = [
      /^127\./,                # 127.0.0.0/8
      /^10\./,                 # 10.0.0.0/8
      /^172\.(1[6-9]|2[0-9]|3[0-1])\./,  # 172.16.0.0/12
      /^192\.168\./,           # 192.168.0.0/16
      /^::1$/,                 # IPv6 localhost
      /^f[cd][0-9a-f]{2}:/i,   # IPv6 unique local addresses
      /^localhost$/i           # localhost
    ]
    
    private_patterns.any? { |pattern| ip_address.match?(pattern) }
  end
end
