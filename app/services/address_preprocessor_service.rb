# frozen_string_literal: true

# Service for preprocessing addresses to improve weather API results
# Extracts city, state/region, and postal code while removing street-level details
class AddressPreprocessorService
  # Preprocess an address to extract the most relevant parts for weather lookup
  # @param address [String] Raw address or location string
  # @return [String] Processed address with only city, state, and postal code if found
  def self.preprocess(address)
    return address if address.blank?
    
    # Simple preprocessing to normalize the input
    processed = address.to_s.strip.downcase
    Rails.logger.info "AddressPreprocessorService: Input address: '#{processed}'"
    
    # First check if it's a simple ZIP code
    if processed =~ /^\d{5}(-\d{4})?$/
      Rails.logger.info "AddressPreprocessorService: Input is a ZIP code: '#{processed}'"
      return processed
    end
    
    # Use Geocoder to find location information
    begin
      Rails.logger.info "AddressPreprocessorService: Geocoding address: '#{processed}'"
      results = Geocoder.search(processed)
      
      if results.present? && results.first.present?
        result = results.first
        Rails.logger.info "AddressPreprocessorService: Geocoder found location: #{result.inspect}"
        
        # Get the most precise location data available
        if result.postal_code.present?
          # If we have a postal code, use that as the most precise identifier
          # This is ideal for the WeatherAPI as it's precise and stable
          location_key = result.postal_code
          Rails.logger.info "AddressPreprocessorService: Using postal code: '#{location_key}'"
        elsif result.coordinates.present? && result.coordinates.all?(&:present?)
          # If no postal code but we have coordinates, use them
          # Format as "lat,lon" - WeatherAPI accepts this format
          location_key = result.coordinates.join(',')
          Rails.logger.info "AddressPreprocessorService: Using coordinates: '#{location_key}'"
        elsif result.city.present? && result.state_code.present?
          # If we have city and state, use that format
          location_key = "#{result.city} #{result.state_code}".downcase
          Rails.logger.info "AddressPreprocessorService: Using city and state: '#{location_key}'"
        elsif result.city.present? && result.country.present?
          # For international locations without state/province info
          location_key = "#{result.city} #{result.country}".downcase
          Rails.logger.info "AddressPreprocessorService: Using city and country: '#{location_key}'"
        else
          # Fallback to the original processed input
          location_key = processed
          Rails.logger.info "AddressPreprocessorService: No precise location data found, using processed input: '#{location_key}'"
        end
        
        return location_key
      else
        Rails.logger.warn "AddressPreprocessorService: Geocoding returned no results for: '#{processed}'"
      end
    rescue => e
      Rails.logger.error "AddressPreprocessorService: Error during geocoding: #{e.message}"
    end
    
    # If all else fails, return the processed input
    Rails.logger.info "AddressPreprocessorService: Using normalized input as fallback: '#{processed}'"
    return processed
  end
end
