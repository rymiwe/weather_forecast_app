class Forecast < ApplicationRecord
  # Validations
  validates :address, :current_temp, :queried_at, presence: true
  validates :zip_code, presence: true, uniqueness: { scope: :queried_at }
  
  # Scopes
  scope :recent, -> { where('queried_at >= ?', Rails.configuration.x.weather.cache_duration.ago).order(queried_at: :desc) }
  
  # Class methods for caching functionality
  
  # Find a cached forecast by zip code if it exists and is recent
  # @param zip_code [String] The ZIP code to look up
  # @return [Forecast, nil] The forecast record or nil if not found/outdated
  def self.find_cached(zip_code)
    return nil if zip_code.blank?
    
    recent.find_by(zip_code: zip_code)
  end
  
  # Create a forecast record from weather service data
  # @param data [Hash] Weather data from WeatherService
  # @return [Forecast] The created forecast record
  def self.create_from_weather_data(data)
    create(
      address: data[:address],
      zip_code: data[:zip_code],
      current_temp: data[:current_temp],
      high_temp: data[:high_temp],
      low_temp: data[:low_temp],
      conditions: data[:conditions],
      extended_forecast: data[:extended_forecast],
      queried_at: data[:queried_at]
    )
  end
  
  # Calculate when the cache for this forecast expires
  # @return [Time] When this forecast's cache expires
  def cache_expires_at
    queried_at + Rails.configuration.x.weather.cache_duration
  end
  
  # Check if this forecast is from cache
  # @return [Boolean] True if this forecast is from cache
  def cached?
    !!(queried_at && Time.now - queried_at < Rails.configuration.x.weather.cache_duration && Time.now - queried_at > 1.minute)
  end
  
  # Get extended forecast data as parsed JSON
  # @return [Array] Array of daily forecast data
  def extended_forecast_data
    return [] if extended_forecast.blank?
    
    JSON.parse(extended_forecast)
  rescue JSON::ParserError
    []
  end
  
  # Determine the appropriate timezone based on the location
  # @return [String] Timezone identifier (e.g., 'America/Los_Angeles')
  def location_timezone
    if zip_code.present?
      zip = zip_code.to_s
      if zip.start_with?('97') || zip.start_with?('971') || zip.start_with?('972')
        return "America/Los_Angeles" # Portland, Oregon and surrounding areas
      end
      
      # Add more zip code based timezone mappings here
      
      # Fallback for US zip codes
      if zip.length == 5 && zip.match?(/\A\d{5}\z/)
        if zip.start_with?('0') || zip.start_with?('1') || zip.start_with?('2')
          return "America/New_York" # East coast
        elsif zip.start_with?('3')
          return "America/Chicago" # Southeast
        elsif zip.start_with?('4') || zip.start_with?('5') || zip.start_with?('6')
          return "America/Chicago" # Midwest/Central
        elsif zip.start_with?('7')
          return "America/Chicago" # South central
        elsif zip.start_with?('8')
          return "America/Denver" # Mountain
        elsif zip.start_with?('9')
          return "America/Los_Angeles" # West coast
        end
      end
    end
    
    # Try to determine timezone from the address
    if address.present?
      downcase_address = address.downcase
      if downcase_address.include?('portland') || downcase_address.include?('oregon') || downcase_address.include?('washington')
        return "America/Los_Angeles"
      elsif downcase_address.include?('new york') || downcase_address.include?('boston') || downcase_address.include?('philadelphia')
        return "America/New_York"
      elsif downcase_address.include?('chicago') || downcase_address.include?('dallas') || downcase_address.include?('houston')
        return "America/Chicago"
      elsif downcase_address.include?('denver') || downcase_address.include?('phoenix') || downcase_address.include?('salt lake')
        return "America/Denver"
      elsif downcase_address.include?('los angeles') || downcase_address.include?('seattle') || downcase_address.include?('san francisco')
        return "America/Los_Angeles"
      end
    end
    
    # Default timezone if we can't determine it
    "UTC"
  end
  
  # Determine the appropriate temperature units based on the location
  # @return [String] 'imperial' or 'metric'
  def location_based_units
    if zip_code.present?
      zip = zip_code.to_s
      # US zip codes should use imperial
      if zip.length == 5 && zip.match?(/\A\d{5}\z/)
        return "imperial"
      end
    end
    
    # Check address for US locations
    if address.present?
      downcase_address = address.downcase
      if downcase_address.match?(/united states|usa|u\.s\.a\.|america|portland|oregon|washington|california|texas|florida|new york/i)
        return "imperial"
      end
    end
    
    # Default to metric for non-US locations
    "metric"
  end
end
