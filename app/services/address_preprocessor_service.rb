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
    
    # Extract zip/postal code
    zip_code = processed.match(/\b\d{5}(?:-\d{4})?\b/)&.to_s
    Rails.logger.info "AddressPreprocessorService: Extracted zip_code: '#{zip_code}'"
    
    # Simple direct approach - extract everything after a comma if it exists
    if processed.include?(',')
      parts = processed.split(',').map(&:strip)
      Rails.logger.info "AddressPreprocessorService: Split by comma into #{parts.size} parts: #{parts.inspect}"
      
      # Check if we have "city, state zip" pattern in the last part
      if parts.size >= 2
        location_part = parts.last
        Rails.logger.info "AddressPreprocessorService: Last part is: '#{location_part}'"
        
        # Look for state abbreviations
        state_match = nil
        
        US_STATES.each do |abbr, full_name|
          # Check for state abbreviation
          if location_part =~ /\b#{abbr.downcase}\b/i
            state_match = abbr.upcase
            Rails.logger.info "AddressPreprocessorService: Found state abbreviation: '#{state_match}'"
            break
          end
          
          # Check for full state name
          if location_part =~ /\b#{Regexp.escape(full_name.downcase)}\b/i
            state_match = abbr.upcase
            Rails.logger.info "AddressPreprocessorService: Found state name: '#{full_name}', using abbr: '#{state_match}'"
            break
          end
        end
        
        # If state found, attempt to extract city
        if state_match
          # For "street, city, state zip" we want the city part
          city_part = parts.size >= 3 ? parts[-2] : parts[0]
          city = city_part.strip
          
          # If city appears to have street details, try to clean it
          if city =~ /^\d+ /
            # Likely a street address in city - just use what comes after the state in location_part
            # Extract what's before the state in the location part
            location_words = location_part.split
            state_index = location_words.index { |word| word.upcase == state_match }
            
            if state_index && state_index > 0
              # Words before state in this part are the city
              city = location_words[0...state_index].join(' ')
              Rails.logger.info "AddressPreprocessorService: Extracted city from last part: '#{city}'"
            else
              # Just use the first non-numeric word from city_part
              city = city_part.gsub(/^\d+\s+[a-z]+\s+[a-z]+\s+/i, '')
              Rails.logger.info "AddressPreprocessorService: Cleaned city from street details: '#{city}'"
            end
          end
          
          # Construct the result
          result = [city, state_match, zip_code].compact.join(' ')
          Rails.logger.info "AddressPreprocessorService: Constructed result: '#{result}'"
          return result
        end
      end
    end
    
    # Try to match 'city state zip' pattern directly
    state_match = nil
    state_position = nil
    
    # First find the state
    US_STATES.each do |abbr, full_name|
      # Try abbreviation (with word boundary)
      if (match = processed.match(/\b#{abbr.downcase}\b/i))
        state_match = abbr.upcase
        state_position = match.begin(0)
        Rails.logger.info "AddressPreprocessorService: Found state '#{state_match}' at position #{state_position}"
        break
      end
      
      # Try full state name
      if (match = processed.match(/\b#{Regexp.escape(full_name.downcase)}\b/i))
        state_match = abbr.upcase
        state_position = match.begin(0)
        Rails.logger.info "AddressPreprocessorService: Found state '#{full_name}' at position #{state_position}, using '#{state_match}'"
        break
      end
    end
    
    if state_match && state_position
      # If we found a state, try to locate the city and zip
      
      # Everything before the state might be city (after removing street address)
      before_state = processed[0...state_position].strip
      Rails.logger.info "AddressPreprocessorService: Content before state: '#{before_state}'"
      
      # Try to extract just the city name
      city = nil
      
      # If comma exists, take the last part before the state
      if before_state.include?(',')
        parts = before_state.split(',').map(&:strip)
        city = parts.last
        Rails.logger.info "AddressPreprocessorService: City from comma-separated part: '#{city}'"
      else
        # No comma, so try to extract city from word pattern
        # If it looks like "123 Street St City", extract "City"
        if before_state =~ /^\d+\s+/
          # Try to find the last word or two as the city
          words = before_state.split
          if words.size >= 3 
            # Skip the street number and street name, assume city is the rest
            street_indicator_index = words.find_index { |w| w =~ /^(street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|court|ct|place|pl|circle|cir|way|parkway|pkwy|highway|hwy)$/i }
            
            if street_indicator_index && street_indicator_index < words.size - 1
              city = words[(street_indicator_index + 1)..-1].join(' ')
              Rails.logger.info "AddressPreprocessorService: Extracted city after street indicator: '#{city}'"
            else
              # Just take the last word as city
              city = words.last
              Rails.logger.info "AddressPreprocessorService: Using last word as city: '#{city}'"
            end
          else
            city = before_state
            Rails.logger.info "AddressPreprocessorService: Using entire before_state as city: '#{city}'"
          end
        else
          # Just use everything before state as city
          city = before_state
          Rails.logger.info "AddressPreprocessorService: Using entire before_state as city: '#{city}'"
        end
      end
      
      # Try to find zip code after state
      after_state = processed[(state_position + state_match.length)..].strip
      Rails.logger.info "AddressPreprocessorService: Content after state: '#{after_state}'"
      
      zip_after_state = after_state.match(/\b\d{5}(?:-\d{4})?\b/)&.to_s
      zip_to_use = zip_after_state || zip_code
      Rails.logger.info "AddressPreprocessorService: Using zip: '#{zip_to_use}'"
      
      # Remove any street name patterns from the city
      if city =~ /\b(street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|court|ct|place|pl|circle|cir|way|parkway|pkwy|highway|hwy)\b/i
        # This looks like it still contains street info - try to find real city
        if city =~ /\b[a-z]+ (street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|court|ct|place|pl|circle|cir|way|parkway|pkwy|highway|hwy) ([a-z]+)\b/i
          # Pattern like "Carlton Street Portland" - extract "Portland"
          city = $2
          Rails.logger.info "AddressPreprocessorService: Extracted city after street name: '#{city}'"
        else
          # Take the last word hoping it's the city
          city = city.split.last
          Rails.logger.info "AddressPreprocessorService: Using last word as city: '#{city}'"
        end
      end
      
      # Final result with city, state, and zip
      result = [city, state_match, zip_to_use].compact.join(' ')
      Rails.logger.info "AddressPreprocessorService: Final result: '#{result}'"
      return result
    end
    
    # Fallback - if just zip code is available, use that
    if zip_code.present?
      Rails.logger.info "AddressPreprocessorService: Fallback to zip code only: '#{zip_code}'"
      return zip_code
    end
    
    # Couldn't extract meaningful parts, return the original
    Rails.logger.info "AddressPreprocessorService: Couldn't extract parts, returning original address"
    address
  end
  
  private
  
  # Hash of US state abbreviations to full names
  US_STATES = {
    "AL" => "Alabama",
    "AK" => "Alaska",
    "AZ" => "Arizona",
    "AR" => "Arkansas",
    "CA" => "California",
    "CO" => "Colorado",
    "CT" => "Connecticut",
    "DE" => "Delaware",
    "DC" => "District of Columbia",
    "FL" => "Florida",
    "GA" => "Georgia",
    "HI" => "Hawaii",
    "ID" => "Idaho",
    "IL" => "Illinois",
    "IN" => "Indiana",
    "IA" => "Iowa",
    "KS" => "Kansas",
    "KY" => "Kentucky",
    "LA" => "Louisiana",
    "ME" => "Maine",
    "MD" => "Maryland",
    "MA" => "Massachusetts",
    "MI" => "Michigan",
    "MN" => "Minnesota",
    "MS" => "Mississippi",
    "MO" => "Missouri",
    "MT" => "Montana",
    "NE" => "Nebraska",
    "NV" => "Nevada",
    "NH" => "New Hampshire",
    "NJ" => "New Jersey",
    "NM" => "New Mexico",
    "NY" => "New York",
    "NC" => "North Carolina",
    "ND" => "North Dakota",
    "OH" => "Ohio",
    "OK" => "Oklahoma",
    "OR" => "Oregon",
    "PA" => "Pennsylvania",
    "RI" => "Rhode Island",
    "SC" => "South Carolina",
    "SD" => "South Dakota",
    "TN" => "Tennessee",
    "TX" => "Texas",
    "UT" => "Utah",
    "VT" => "Vermont",
    "VA" => "Virginia",
    "WA" => "Washington",
    "WV" => "West Virginia",
    "WI" => "Wisconsin",
    "WY" => "Wyoming"
  }.freeze
end
