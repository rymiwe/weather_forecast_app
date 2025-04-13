# frozen_string_literal: true

# Service for preprocessing addresses to improve weather API results
# Extracts city, state/region, and postal code while removing street-level details
class AddressPreprocessorService
  # Preprocess an address to extract the most relevant parts for weather lookup
  # @param address [String] Raw address or location string
  # @return [String] Processed address with only city, state, and postal code if found
  def self.preprocess(address)
    return address if address.blank?
    
    # Simple preprocessing for certain cases
    processed = address.to_s.strip.downcase
    Rails.logger.info "AddressPreprocessorService: Input address: '#{processed}'"
    
    # CASE 1: Comma-separated address (like "123 Street Name, City, State ZIP")
    if processed.include?(',')
      parts = processed.split(',').map(&:strip)
      Rails.logger.info "AddressPreprocessorService: Split by comma: #{parts.inspect}"
      
      # If we have at least 2 parts, check the second-to-last part for city
      if parts.size >= 2
        # For addresses like "Street, City, State ZIP"
        # The second-to-last part is likely the city
        city_part = parts[-2]
        last_part = parts[-1]
        
        # Check for state abbreviation or name in the last part
        state_match = nil
        
        US_STATES.each do |abbr, name|
          if last_part =~ /\b#{abbr}\b/i || last_part =~ /\b#{Regexp.escape(name)}\b/i
            state_match = abbr.upcase
            Rails.logger.info "AddressPreprocessorService: Found state '#{state_match}' in last part"
            break
          end
        end
        
        # If we found a state, construct the result with city and state
        if state_match && city_part.present?
          # Clean up the city part if needed (remove any leading numbers, etc.)
          city = city_part.gsub(/^\d+\s+/, '')
          
          # For the case "3824 SE Carlton Street, Portland, OR 97202"
          # city would be "Portland"
          result = [city, state_match].compact.join(' ').downcase
          Rails.logger.info "AddressPreprocessorService: Extracted from comma-separated: '#{result}'"
          return result
        end
      end
    end
    
    # CASE 2: Try to extract state abbreviation and city
    state_match = nil
    state_position = nil
    
    US_STATES.each do |abbr, name|
      # Try to match state abbreviation
      if processed =~ /\b#{abbr}\b/i
        state_match = abbr.upcase
        state_position = processed.index(/\b#{abbr}\b/i)
        Rails.logger.info "AddressPreprocessorService: Found state abbreviation '#{state_match}' at position #{state_position}"
        break
      end
      
      # Try to match full state name
      if processed =~ /\b#{name}\b/i
        state_match = abbr.upcase
        state_position = processed.index(/\b#{name}\b/i)
        Rails.logger.info "AddressPreprocessorService: Found state name '#{name}' at position #{state_position}"
        break
      end
    end
    
    if state_match && state_position
      # Special case for addresses with "Street" followed by city and state
      # For example: "3824 SE Carlton Street Portland OR 97202"
      if processed =~ /\b(street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|court|ct)\b/i
        # Find the street type word
        street_match = processed.match(/\b(street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|court|ct)\b/i)
        
        if street_match && street_match.end(0) < state_position
          # If there's text between street type and state, that's likely the city
          text_between = processed[street_match.end(0)...state_position].strip
          
          if text_between.present?
            # Use the text between as the city
            city = text_between
            Rails.logger.info "AddressPreprocessorService: Found city '#{city}' between street type and state"
          else
            # Try words before the street type
            before_street = processed[0...street_match.begin(0)].strip
            words = before_street.split(/\s+/)
            # Take the last non-numeric word as potential city name
            city = words.reverse.find { |w| w !~ /^\d+$/ }
            Rails.logger.info "AddressPreprocessorService: Used word before street type as city: '#{city}'"
          end
          
          if city.present?
            result = [city, state_match].compact.join(' ').downcase
            Rails.logger.info "AddressPreprocessorService: Final result with street handling: '#{result}'"
            return result
          end
        end
      end
      
      # If no special case matched, take the last word before state as city
      before_state = processed[0...state_position].strip
      words = before_state.split(/\s+/)
      city = words.last if words.any?
      
      if city
        result = [city, state_match].compact.join(' ').downcase
        Rails.logger.info "AddressPreprocessorService: Simple extraction result: '#{result}'"
        return result
      end
    end
    
    # CASE 3: Extract zip code only if no city/state found
    zip_code = processed.match(/\b\d{5}(?:-\d{4})?\b/)&.to_s
    if zip_code.present?
      Rails.logger.info "AddressPreprocessorService: Using zip code only: '#{zip_code}'"
      return zip_code
    end
    
    # CASE 4: Fallback - If we couldn't extract anything meaningful, use the original
    Rails.logger.info "AddressPreprocessorService: No extraction possible, using normalized input: '#{processed}'"
    return processed
  end
  
  private
  
  US_STATES = {
    'al' => 'alabama',
    'ak' => 'alaska',
    'az' => 'arizona',
    'ar' => 'arkansas',
    'ca' => 'california',
    'co' => 'colorado',
    'ct' => 'connecticut',
    'de' => 'delaware',
    'fl' => 'florida',
    'ga' => 'georgia',
    'hi' => 'hawaii',
    'id' => 'idaho',
    'il' => 'illinois',
    'in' => 'indiana',
    'ia' => 'iowa',
    'ks' => 'kansas',
    'ky' => 'kentucky',
    'la' => 'louisiana',
    'me' => 'maine',
    'md' => 'maryland',
    'ma' => 'massachusetts',
    'mi' => 'michigan',
    'mn' => 'minnesota',
    'ms' => 'mississippi',
    'mo' => 'missouri',
    'mt' => 'montana',
    'ne' => 'nebraska',
    'nv' => 'nevada',
    'nh' => 'new hampshire',
    'nj' => 'new jersey',
    'nm' => 'new mexico',
    'ny' => 'new york',
    'nc' => 'north carolina',
    'nd' => 'north dakota',
    'oh' => 'ohio',
    'ok' => 'oklahoma',
    'or' => 'oregon',
    'pa' => 'pennsylvania',
    'ri' => 'rhode island',
    'sc' => 'south carolina',
    'sd' => 'south dakota',
    'tn' => 'tennessee',
    'tx' => 'texas',
    'ut' => 'utah',
    'vt' => 'vermont',
    'va' => 'virginia',
    'wa' => 'washington',
    'wv' => 'west virginia',
    'wi' => 'wisconsin',
    'wy' => 'wyoming',
    'dc' => 'district of columbia'
  }.freeze
end
