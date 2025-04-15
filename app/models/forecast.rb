# frozen_string_literal: true

# Forecast model for storing weather data
# == Schema Information
#
# Table name: forecasts
#
#  id                 :integer          not null, primary key
#  address            :string           not null
#  normalized_address :string           indexed
#  zip_code           :string           indexed
#  current_temp       :float            not null
#  high_temp          :float            not null
#  low_temp           :float            not null
#  conditions         :string
#  extended_forecast  :text
#  queried_at         :datetime         not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_forecasts_on_normalized_address  (normalized_address)
#  index_forecasts_on_zip_code            (zip_code)
#
# Cache Keys
#
# The following attributes are used as cache keys:
#  - normalized_address: Normalized version of the search query (primary cache key)
#  - zip_code: Extracted from address if available (secondary cache key)
#
# Cache TTL: Controlled by ENV['FORECAST_CACHE_TTL'] (defaults to 30 minutes)
#
class Forecast < ApplicationRecord
  validates :address, presence: true
  validates :current_temp, :high_temp, :low_temp, presence: true, numericality: true
  
  # Virtual attribute to track whether a forecast was retrieved from cache
  attr_accessor :from_cache
  
  # Virtual attribute to store the preprocessed address used for API calls
  attr_accessor :api_query
  
  # Virtual attribute to store the exact search string entered by the user
  attr_accessor :user_query
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  
  # Get display units for the forecast
  # @return [String] 'imperial' for US locations, 'metric' for others
  def display_units
    should_use_imperial? ? 'imperial' : 'metric'
  end
  
  # Display temperature for the current weather, with correct units
  # @param use_imperial [Boolean] Whether to use imperial units
  # @param temp [Float, nil] Optional override temperature
  # @return [String] Formatted temperature string
  def display_temperature(use_imperial: false, temp: nil)
    temp_value = temp || (if use_imperial
                            forecast_data&.dig('current', 'temp_f') || convert_to_fahrenheit(current_temp)
                          else
                            forecast_data&.dig('current', 'temp_c') || current_temp
                          end)
    use_imperial ? "#{temp_value.round}°F" : "#{temp_value.round}°C"
  end
  
  # Format current temperature for display
  # @return [String] Formatted temperature with unit
  def current_temp_display
    display_temperature(use_imperial: should_use_imperial?)
  end
  
  # Format high/low temperature for display
  # @return [String] Formatted high/low with units
  def high_low_display
    if should_use_imperial?
      high = forecast_data&.dig('forecast', 'forecastday', 0, 'day', 'maxtemp_f') || 
             convert_to_fahrenheit(high_temp)
      low = forecast_data&.dig('forecast', 'forecastday', 0, 'day', 'mintemp_f') || 
            convert_to_fahrenheit(low_temp)
      "#{high.round}°F / #{low.round}°F"
    else
      high = forecast_data&.dig('forecast', 'forecastday', 0, 'day', 'maxtemp_c') || 
             high_temp
      low = forecast_data&.dig('forecast', 'forecastday', 0, 'day', 'mintemp_c') || 
            low_temp
      "#{high.round}°C / #{low.round}°C"
    end
  end
  
  # Format temperature for display with units
  # @param temp [Float] Temperature in Celsius
  # @return [String] Formatted temperature with unit
  def format_temp(temp)
    display_temperature(use_imperial: should_use_imperial?, temp: temp)
  end
  
  # Convert Celsius to Fahrenheit
  # @param celsius [Float] Temperature in Celsius
  # @return [Float] Temperature in Fahrenheit
  def convert_to_fahrenheit(celsius)
    (celsius * 9/5) + 32
  end
  
  # Check if forecast is for a US location
  # @return [Boolean] true if location is in the US
  def should_use_imperial?
    country = forecast_data&.dig('location', 'country')
    country = country.to_s
    country.include?("United States of America") || country == "USA"
  end
  
  # Get the timezone for the forecast location
  # @return [ActiveSupport::TimeZone] Timezone object
  def location_timezone
    timezone_name = forecast_data&.dig('timezone')
    
    if timezone_name.present?
      # Convert seconds offset to hours
      offset_hours = timezone_name.to_i / 3600
      "Etc/GMT#{offset_hours.positive? ? "-" : "+"}#{offset_hours.abs}"
    else
      # Default to Pacific Time for US, UTC otherwise
      should_use_imperial? ? "America/Los_Angeles" : "UTC"
    end
  end
  
  # Format a timestamp in the location's timezone
  # @param time [Time] Time to format
  # @param format [String] strftime format string
  # @return [String] Formatted time string
  def format_time_in_local_zone(time, format="%A, %B %d, %Y at %I:%M %p")
    # Set the time zone for display based on location
    tz = ActiveSupport::TimeZone[location_timezone] || Time.zone
    time.in_time_zone(tz).strftime(format)
  end

  # Find a forecast by zip code in cache
  # @param zip_code [String] Zip code to find
  # @return [Forecast, nil] Found forecast or nil
  def self.find_cached(zip_code)
    return nil unless zip_code.present?
    
    # Look for a forecast in the cache window (30 minutes by default)
    where(zip_code: zip_code)
      .where('queried_at >= ?', Time.current - cache_duration)
      .order(queried_at: :desc)
      .first
  end
  
  # Find a forecast by normalized address in cache
  # @param address [String] Address to find
  # @return [Forecast, nil] Found forecast or nil
  def self.find_cached_by_address(address)
    return nil unless address.present?
    
    normalized_address = normalize_address(address)
    # Look for a forecast in the cache window (30 minutes by default)
    where(normalized_address: normalized_address)
      .where('queried_at >= ?', Time.current - cache_duration)
      .order(queried_at: :desc)
      .first
  end
  
  # Normalize an address for consistent caching
  # @param address [String] Address to normalize
  # @return [String] Normalized address
  def self.normalize_address(address)
    # Special case for coordinates (lat,lon format)
    if address.to_s.match?(/^\s*-?\d+\.\d+\s*,\s*-?\d+\.\d+\s*$/)
      # For coordinates, just clean up any extra spaces but preserve the format
      return address.to_s.strip.gsub(/\s+/, '')
    end
    
    # For all other addresses, use the regular normalization
    # Remove commas, extra spaces, convert to lowercase, and replace spaces with underscores
    address.to_s.strip.downcase.gsub(/,/, '').gsub(/\s+/, ' ').gsub(/\s/, '_')
  end
  
  # Get the cache duration
  # @return [ActiveSupport::Duration] Cache duration
  def self.cache_duration
    ENV.fetch('FORECAST_CACHE_TTL', 30).to_i.minutes
  end
  
  # Create a sample forecast with mock data
  # @param address [String] Address for the forecast
  # @return [Forecast] Created forecast
  def self.sample(address=nil)
    address ||= 'Sample Location'
    
    create(
      address: address,
      zip_code: address.to_s.match(/\d{5}/)&.to_s,
      current_temp: 22,
      high_temp: 25,
      low_temp: 18,
      conditions: 'clear sky',
      extended_forecast: sample_forecast_data.to_json,
      queried_at: Time.current
    )
  end
  
  # Create a forecast from API response data
  # @param address [String] Address for this forecast
  # @param api_response [Hash] API response data
  # @return [Forecast, nil] Created forecast or nil if creation failed
  def self.create_from_api_response(address, api_response)
    return nil unless api_response.present?
    
    begin
      Rails.logger.info "Forecast.create_from_api_response: Creating forecast for #{address}"
      
      # Extract zip code from address if possible
      zip_code = nil
      if address.present?
        zip_match = address.to_s.match(/\b\d{5}\b/)
        zip_code = zip_match[0] if zip_match
      end
      
      # Get normalized address for consistent caching
      normalized_address = normalize_address(address)
      
      # Safely extract current weather data with fallbacks
      current = api_response[:current] || api_response["current"] || {}
      
      # Extract main weather data based on the API format
      main = current[:main] || current["main"] || {}
      
      # Get current temperature
      current_temp = main["temp"] || current["temp_c"] || current["temp"] || 22
      
      # Get high temperature
      forecast_data = api_response[:forecast] || api_response["forecast"] || {}
      today_forecast = nil
      
      if forecast_data.has_key?("forecastday") && !forecast_data["forecastday"].empty?
        today_forecast = forecast_data["forecastday"][0]
      end
      
      high_temp = nil
      if today_forecast && today_forecast.has_key?("day")
        high_temp = today_forecast["day"]["maxtemp_c"]
      end
      
      high_temp ||= main["temp_max"] || current["maxtemp_c"] || (current_temp + 5)
      
      # Get low temperature
      low_temp = nil
      if today_forecast && today_forecast.has_key?("day")
        low_temp = today_forecast["day"]["mintemp_c"]
      end
      
      low_temp ||= main["temp_min"] || current["mintemp_c"] || (current_temp - 5)
      
      # Get weather conditions
      weather = current[:weather] || current["weather"] || []
      weather = [weather] unless weather.is_a?(Array) 
      
      conditions = nil
      if current.has_key?("condition") && current["condition"].has_key?("text")
        conditions = current["condition"]["text"]
      elsif !weather.empty? && weather[0].has_key?("description")
        conditions = weather[0]["description"]
      else
        conditions = "Clear"
      end
      
      # Create and return the forecast
      forecast = create(
        address: address,
        normalized_address: normalized_address,
        zip_code: zip_code,
        current_temp: current_temp,
        high_temp: high_temp,
        low_temp: low_temp,
        conditions: conditions,
        extended_forecast: api_response.to_json,
        queried_at: Time.current
      )
      
      Rails.logger.info "Forecast.create_from_api_response: Created forecast with ID: #{forecast.id}"
      forecast
    rescue StandardError => e
      Rails.logger.error "Forecast.create_from_api_response: Error creating forecast: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end
  
  # Create a mock forecast for testing and development
  def self.mock_forecast(address)
    Rails.logger.info "Forecast.mock_forecast: Creating mock forecast for address: #{address}"
    # Use default mock data
    is_us = address.to_s.match?(/usa|us$|united states|america|san francisco|new york|chicago|miami/i)
    
    # Create a basic forecast with mock data
    temp = is_us ? 75 : 20
    high = is_us ? 80 : 22
    low = is_us ? 65 : 15
    
    # Return a properly formatted mock forecast
    now = Time.current
    mock_data = {
      current: {
        "main" => {
          "temp" => is_us ? 24 : 20, # temperatures in C for storage
          "temp_min" => is_us ? 20 : 18,
          "temp_max" => is_us ? 28 : 22
        },
        "weather" => [
          { "description" => is_us ? "clear sky" : "light rain" }
        ],
        "sys" => {
          "country" => is_us ? "US" : "GB"
        }
      },
      forecast: {
        "list" => (1..5).map do |i|
          {
            "dt" => now.advance(days: i).to_i,
            "main" => {
              "temp" => is_us ? 24 : 20,
              "temp_min" => is_us ? 20 : 18,
              "temp_max" => is_us ? 28 : 22
            },
            "weather" => [
              { "description" => ["clear sky", "few clouds", "scattered clouds", "light rain", 
                                  "overcast clouds"].sample }
            ]
          }
        end
      }
    }
    
    begin
      forecast = new(
        address: address,
        zip_code: address.to_s.match(/\d{5}/)&.to_s,
        current_temp: mock_data[:current]["main"]["temp"],
        high_temp: mock_data[:current]["main"]["temp_max"],
        low_temp: mock_data[:current]["main"]["temp_min"],
        conditions: mock_data[:current]["weather"][0]["description"],
        extended_forecast: mock_data.to_json,
        queried_at: Time.current
      )
      
      if forecast.save
        Rails.logger.info "Forecast.mock_forecast: Successfully created forecast ID: #{forecast.id}"
        forecast
      else
        mock_forecast_save_failed(forecast)
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Forecast.mock_forecast: Error creating forecast: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end
  
  def self.mock_forecast_save_failed(forecast)
    # Log the error but don't raise it, as we can still use the mock data
    Rails.logger.error "Forecast.mock_forecast: Failed to save forecast: " \
                       "#{forecast.errors.full_messages.join(', ')}"
  end
  
  # Check if the forecast is from cache and cache is still fresh
  # @return [Boolean] True if from cache and fresh
  def cache_fresh?
    Time.now - queried_at < self.class.cache_duration
  end
  
  # Get parsed forecast data
  # @return [Hash, nil] Parsed forecast data
  def forecast_data
    @forecast_data ||= ForecastParserService.parse(extended_forecast)
  end
  
  # Get extended forecast data for the view
  # @return [Array] Array of daily forecast data
  def extended_forecast_data
    return [] unless forecast_data.present?
    ForecastParserService.extract_daily_forecasts(forecast_data)
  end
  
  # Get daily forecasts
  # @return [Array] Array of daily forecasts
  def daily_forecasts
    return [] unless forecast_data.present?
    ForecastParserService.extract_daily_forecasts(forecast_data)
  end
  
  # Get current weather data
  # @return [Hash] Current weather data
  def current_weather
    return {} unless forecast_data.present?
    ForecastParserService.extract_current_weather(forecast_data)
  end
  
  # Get current condition hash (for robust view rendering)
  def current_condition
    forecast_data&.dig('current', 'condition') || {}
  end
  
  # Returns an array of forecast day hashes for the view
  # Optionally applies timezone and unit conversion
  # @param timezone [ActiveSupport::TimeZone, nil]
  # @param use_imperial [Boolean]
  def forecast_days(timezone: nil, use_imperial: false)
    days = forecast_data&.dig('forecast', 'forecastday') || []
    days.map do |day|
      date = day['date']
      local_date = begin
        timezone ? timezone.parse(date) : Date.parse(date)
      rescue StandardError
        date
      end
      day_name = local_date.respond_to?(:strftime) ? local_date.strftime('%A') : date.to_s
      {
        date: local_date,
        day_name: day_name,
        high: use_imperial ? day['day']['maxtemp_f'] : day['day']['maxtemp_c'],
        low: use_imperial ? day['day']['mintemp_f'] : day['day']['mintemp_c'],
        condition: day['day']['condition'],
        icon: day['day']['condition']&.dig('icon'),
        text: day['day']['condition']&.dig('text')
      }
    end
  end

  private
  
  # Sample forecast data for testing
  def self.sample_forecast_data
    {
      current: {
        "main" => {
          "temp" => 22,
          "temp_min" => 18,
          "temp_max" => 25
        },
        "weather" => [
          { "description" => "clear sky" }
        ],
        "sys" => {
          "country" => "US"
        }
      },
      forecast: {
        "list" => (1..5).map do |i|
          {
            "dt" => Time.current.advance(days: i).to_i,
            "main" => {
              "temp" => 22,
              "temp_min" => 18,
              "temp_max" => 25
            },
            "weather" => [
              { "description" => ["clear sky", "few clouds", "scattered clouds"].sample }
            ]
          }
        end
      }
    }
  end
end
