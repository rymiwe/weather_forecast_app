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
    
    # Try using WeatherAPI Search/Autocomplete API first
    api_result = search_using_weatherapi(processed)
    
    if api_result.present?
      Rails.logger.info "AddressPreprocessorService: Used WeatherAPI Search, result: '#{api_result}'"
      return api_result
    end
    
    # Fall back to simple preprocessing if API fails or returns no results
    Rails.logger.info "AddressPreprocessorService: Weather API search returned no results, falling back to simple preprocessing"
    
    # Extract zip/postal code
    zip_code = processed.match(/\b\d{5}(?:-\d{4})?\b/)&.to_s
    Rails.logger.info "AddressPreprocessorService: Extracted zip_code: '#{zip_code}'"
    
    # Simple direct approach - extract everything after a comma if it exists
    if processed.include?(',')
      parts = processed.split(',').map(&:strip)
      Rails.logger.info "AddressPreprocessorService: Split by comma: #{parts.inspect}"
      
      # Focus on the last two parts (usually city, state/zip)
      relevant_parts = parts.last(2)
      Rails.logger.info "AddressPreprocessorService: Using relevant parts: #{relevant_parts.inspect}"
      
      # Check for state in the last part
      last_part = relevant_parts.last
      state_match = nil
      
      # Try to match state abbreviation or name
      US_STATES.each do |abbr, name|
        if last_part.match(/\b#{abbr}\b/i) || last_part.match(/\b#{name}\b/i)
          state_match = abbr.upcase
          state_position = last_part.match(/\b#{abbr}\b/i) ? last_part.index(/\b#{abbr}\b/i) : last_part.index(/\b#{name}\b/i)
          Rails.logger.info "AddressPreprocessorService: Found state: '#{state_match}' at position #{state_position}"
          break
        end
      end
      
      # Extract city (usually before the state in the last part, or the entire second-to-last part)
      city = if state_match && relevant_parts.size > 1
               if state_position && state_position > 0
                 # Take everything before the state in the last part
                 city_part = last_part[0...state_position].strip
                 city_part.present? ? city_part : relevant_parts.first
               else
                 relevant_parts.first
               end
             elsif relevant_parts.size > 1
               relevant_parts.first
             else
               last_part
             end
      
      Rails.logger.info "AddressPreprocessorService: Extracted city: '#{city}'"
      
      # If city part contains numbers, it's likely a street address - try to extract just the city
      if city =~ /\d+/
        Rails.logger.info "AddressPreprocessorService: City contains numbers, trying to extract just city name"
        
        # Try to identify words that look like a city name (not numeric, not ordinals like 1st, 2nd)
        words = city.split(/\s+/)
        city_words = words.select { |w| w !~ /\d/ && w !~ /\b(\d+(?:st|nd|rd|th))\b/i }
        
        if city_words.any?
          city = city_words.join(' ')
          Rails.logger.info "AddressPreprocessorService: Extracted city name without numbers: '#{city}'"
        end
      end
      
      # Try to find state in the parts array if we didn't find it in the last part
      if !state_match && parts.size > 1
        parts.each do |part|
          US_STATES.each do |abbr, name|
            if part.match(/\b#{abbr}\b/i) || part.match(/\b#{name}\b/i)
              state_match = abbr.upcase
              state_position = part.match(/\b#{abbr}\b/i) ? part.index(/\b#{abbr}\b/i) : part.index(/\b#{name}\b/i)
              Rails.logger.info "AddressPreprocessorService: Found state in another part: '#{state_match}' at position #{state_position}"
              break
            end
          end
          break if state_match
        end
      end
      
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
      result = [city, state_match, zip_code].compact.join(' ')
      Rails.logger.info "AddressPreprocessorService: Final result: '#{result}'"
      return result
    end
    
    # If no comma, try to find state abbreviation or name
    state_match = nil
    state_position = nil
    
    US_STATES.each do |abbr, name|
      # Try to match abbreviation with word boundaries (not part of another word)
      if processed =~ /\b#{abbr}\b/i
        state_match = abbr.upcase
        state_position = processed.index(/\b#{abbr}\b/i)
        Rails.logger.info "AddressPreprocessorService: Found state abbreviation: '#{state_match}' at position #{state_position}"
        break
      end
      
      # Try to match full state name
      if processed =~ /\b#{name}\b/i
        state_match = abbr.upcase
        state_position = processed.index(/\b#{name}\b/i)
        Rails.logger.info "AddressPreprocessorService: Found state name: '#{state_match}' (#{name}) at position #{state_position}"
        break
      end
    end
    
    if state_match && state_position
      # Get everything before the state match, which is likely the city
      city = processed[0...state_position].strip
      
      # If city part contains numbers, it's likely a street address - try to extract just the city
      if city =~ /\d+/
        Rails.logger.info "AddressPreprocessorService: City contains numbers, trying to extract just city name"
        
        # Try to identify words that look like a city name (not numeric, not ordinals like 1st, 2nd)
        words = city.split(/\s+/)
        city_words = words.select { |w| w !~ /\d/ && w !~ /\b(\d+(?:st|nd|rd|th))\b/i }
        
        if city_words.any?
          city = city_words.join(' ')
          Rails.logger.info "AddressPreprocessorService: Extracted city name without numbers: '#{city}'"
        end
      end
      
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
      
      # Try to find zip code after state
      after_state = processed[(state_position + state_match.length)..].strip
      Rails.logger.info "AddressPreprocessorService: Content after state: '#{after_state}'"
      zip_after_state = after_state.match(/\b\d{5}(?:-\d{4})?\b/)&.to_s
      zip_to_use = zip_after_state || zip_code
      Rails.logger.info "AddressPreprocessorService: Using zip: '#{zip_to_use}'"
      
      # Final result with city, state, and zip
      result = [city, state_match, zip_to_use].compact.join(' ')
      Rails.logger.info "AddressPreprocessorService: Final result: '#{result}'"
      return result
    end
    
    # If we found a zip code but no state, try to use just that
    if zip_code.present?
      Rails.logger.info "AddressPreprocessorService: Using zip code only: '#{zip_code}'"
      return zip_code
    end
    
    # If all else fails, return the original (just normalized)
    Rails.logger.info "AddressPreprocessorService: No patterns matched, returning normalized address: '#{processed}'"
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

  def self.search_using_weatherapi(query)
    begin
      # Get API key from environment
      api_key = ENV['WEATHERAPI_KEY']
      return nil unless api_key.present?
      
      # Prepare the URL with proper encoding
      encoded_query = URI.encode_www_form_component(query)
      uri = URI("http://api.weatherapi.com/v1/search.json?key=#{api_key}&q=#{encoded_query}")
      
      # Make the API request
      response = Net::HTTP.get_response(uri)
      
      # Check if request was successful
      if response.code.to_i == 200
        results = JSON.parse(response.body)
        
        # Check if we have any results
        if results.present? && results.is_a?(Array) && results.first.present?
          # Get the first (most relevant) result
          location = results.first
          
          # Extract the important parts for our needs
          city = location['name']
          region = location['region']&.split(',')&.first&.strip # Get just the first part of region if it has commas
          country = location['country']
          
          # For US locations, try to extract state abbreviation
          if country == 'United States of America' && region.present?
            # Try to find state abbreviation
            US_STATES.each do |abbr, name|
              if region.downcase == name || region.downcase.include?(name)
                region = abbr.upcase
                break
              end
            end
          end
          
          # Format the result (different formats for US vs international)
          if country == 'United States of America'
            # US format: city state zip (zip is optional)
            return [city, region].compact.join(' ').downcase
          else
            # International format: city, country
            return [city, country].compact.join(', ').downcase
          end
        end
      else
        Rails.logger.warn "AddressPreprocessorService: WeatherAPI search failed with code #{response.code}: #{response.body}"
      end
    rescue => e
      Rails.logger.error "AddressPreprocessorService: Error using WeatherAPI search: #{e.message}"
    end
    
    # Return nil if anything fails, so we fall back to basic preprocessing
    nil
  end
end
