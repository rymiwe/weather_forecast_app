# frozen_string_literal: true

# Service for extracting ZIP codes from addresses
# Following DRY principles by centralizing this logic
class ZipCodeExtractionService
  # Regular expression for US zip codes (5 digits, optionally followed by hyphen and 4 more digits)
  US_ZIP_CODE_PATTERN = /\b\d{5}(?:-\d{4})?\b/.freeze
  
  # Extract zip code from address string
  # @param address [String] The address to parse
  # @return [String, nil] The zip code or nil if not found
  def self.extract_from_address(address)
    return nil if address.blank?
    
    match = address.to_s.match(US_ZIP_CODE_PATTERN)
    match[0] if match
  end
  
  # Extract postal code from location data (useful when working with geocoding APIs)
  # @param location_data [Hash] Location data from geocoding service
  # @param postal_code_key [Symbol] Key where postal code might be found
  # @return [String, nil] The postal code or nil if not found
  def self.extract_from_location_data(location_data, postal_code_key: :postcode)
    return nil unless location_data.is_a?(Hash)
    
    # Try different common formats
    location_data['zip'] || 
      location_data[:zip] ||
      location_data['postal_code'] ||
      location_data[:postal_code] ||
      (location_data['local_names'] && location_data['local_names'][postal_code_key.to_s]) ||
      extract_from_address(location_data['formatted_address'])
  end
end
