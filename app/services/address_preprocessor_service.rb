# frozen_string_literal: true

# Service for preprocessing addresses to improve weather API results
# Extracts city, state/region, and postal code while removing street-level details
class AddressPreprocessorService
  # Precision for rounding coordinates (5 decimal places is about 1.1 meters precision)
  COORDINATE_PRECISION = 4

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
      Rails.logger.info "AddressPreprocessorService: Input is a US ZIP code: '#{processed}'"
      
      # For US ZIP codes, try geocoding with country bias
      begin
        # Make sure the geocoder knows this is a US ZIP
        us_zip = "#{processed},usa"
        Rails.logger.info "AddressPreprocessorService: Geocoding US ZIP code: '#{us_zip}'"
        results = Geocoder.search(us_zip)
        
        if results.present? && results.first.present? && results.first.coordinates.present? && results.first.coordinates.all?(&:present?)
          coordinates = format_coordinates(results.first.coordinates)
          Rails.logger.info "AddressPreprocessorService: Successfully geocoded ZIP code to coordinates: '#{coordinates}'"
          return coordinates
        else
          Rails.logger.warn "AddressPreprocessorService: Geocoding of US ZIP code failed to return valid coordinates"
          return nil
        end
      rescue => e
        Rails.logger.error "AddressPreprocessorService: Error geocoding US ZIP code: #{e.message}"
        return nil
      end
    end
    
    # Use Geocoder to find location information
    begin
      Rails.logger.info "AddressPreprocessorService: Geocoding address: '#{processed}'"
      results = Geocoder.search(processed)
      
      if results.present? && results.first.present?
        result = results.first
        Rails.logger.info "AddressPreprocessorService: Geocoder found location: #{result.inspect}"
        
        # Always use coordinates when available
        if result.coordinates.present? && result.coordinates.all?(&:present?)
          coordinates = format_coordinates(result.coordinates)
          Rails.logger.info "AddressPreprocessorService: Using coordinates: '#{coordinates}'"
          return coordinates
        elsif result.postal_code.present?
          # If no coordinates but we have a postal code, try geocoding it to get coordinates
          postal_results = Geocoder.search(result.postal_code)
          if postal_results.present? && postal_results.first.present? && 
             postal_results.first.coordinates.present? && postal_results.first.coordinates.all?(&:present?)
            coordinates = format_coordinates(postal_results.first.coordinates)
            Rails.logger.info "AddressPreprocessorService: Converted postal code to coordinates: '#{coordinates}'"
            return coordinates
          else
            Rails.logger.warn "AddressPreprocessorService: Could not geocode postal code to coordinates"
            return nil
          end
        elsif result.city.present? && (result.state_code.present? || result.country.present?)
          # If we have city and state/country but no coordinates, try geocoding the city
          location = [result.city, result.state_code || result.country].compact.join(' ')
          city_results = Geocoder.search(location)
          if city_results.present? && city_results.first.present? && 
             city_results.first.coordinates.present? && city_results.first.coordinates.all?(&:present?)
            coordinates = format_coordinates(city_results.first.coordinates)
            Rails.logger.info "AddressPreprocessorService: Converted city to coordinates: '#{coordinates}'"
            return coordinates
          else
            Rails.logger.warn "AddressPreprocessorService: Could not geocode city to coordinates"
            return nil
          end
        else
          Rails.logger.warn "AddressPreprocessorService: Geocoding result doesn't have usable location information"
          return nil
        end
      else
        Rails.logger.warn "AddressPreprocessorService: Geocoding returned no results for: '#{processed}'"
        return nil
      end
    rescue => e
      Rails.logger.error "AddressPreprocessorService: Error during geocoding: #{e.message}"
      return nil
    end
  end
  
  private
  
  # Format coordinates with consistent precision for caching and API queries
  def self.format_coordinates(coordinates)
    lat = coordinates[0].to_f.round(COORDINATE_PRECISION)
    lon = coordinates[1].to_f.round(COORDINATE_PRECISION)
    
    # Use the same format for both API queries and cache keys
    # The normalize_address method in Forecast model has been updated to handle this format
    "#{lat},#{lon}"
  end
end
