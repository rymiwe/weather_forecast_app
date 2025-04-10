# frozen_string_literal: true

# Forecast model for storing weather data
class Forecast < ApplicationRecord
  validates :address, presence: true
  validates :current_temp, :high_temp, :low_temp, presence: true, numericality: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  
  # Get display units for the forecast
  # @return [String] 'imperial' for US locations, 'metric' for others
  def display_units
    should_use_imperial? ? 'imperial' : 'metric'
  end
  
  # Format current temperature for display
  # @return [String] Formatted temperature with unit
  def current_temp_display
    format_temp(current_temp)
  end
  
  # Format high/low temperature for display
  # @return [String] Formatted high/low with units
  def high_low_display
    "#{format_temp(high_temp)} / #{format_temp(low_temp)}"
  end
  
  # Format temperature for display with units
  # @param temp [Float] Temperature in Celsius
  # @return [String] Formatted temperature with unit
  def format_temp(temp)
    if should_use_imperial?
      "#{convert_to_fahrenheit(temp).round}°F"
    else
      "#{temp.round}°C"
    end
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
    # Check country code from API response first
    country = forecast_data&.dig('current_weather', 'sys', 'country') || 
              forecast_data&.dig('sys', 'country')
    
    return true if country == 'US'
    
    # Fallback to checking the address string
    address.to_s.match?(/usa|us$|united states|america/i) ||
      zip_code.to_s.match?(/^\d{5}$/)
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
    
    current = api_response[:current_weather] || api_response["current_weather"]
    return nil unless current.present? && current["main"].present? && current["weather"].present?
    
    begin
      Rails.logger.info "Forecast.create_from_api_response: Creating forecast for #{address}"
      
      # Extract zip code from address if possible
      zip_code = address.to_s.match(/\d{5}/)&.to_s
      
      # Extract required data from API response
      current_temp = current["main"]["temp"]
      high_temp = current["main"]["temp_max"]
      low_temp = current["main"]["temp_min"]
      conditions = current["weather"][0]["description"]
      
      # Create and return the forecast
      forecast = create(
        address: address,
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
      current_weather: {
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
              { "description" => ["clear sky", "few clouds", "scattered clouds", "light rain", "overcast clouds"].sample }
            ]
          }
        end
      }
    }
    
    begin
      forecast = new(
        address: address,
        zip_code: address.to_s.match(/\d{5}/)&.to_s,
        current_temp: mock_data[:current_weather]["main"]["temp"],
        high_temp: mock_data[:current_weather]["main"]["temp_max"],
        low_temp: mock_data[:current_weather]["main"]["temp_min"],
        conditions: mock_data[:current_weather]["weather"][0]["description"],
        extended_forecast: mock_data.to_json,
        queried_at: Time.current
      )
      
      if forecast.save
        Rails.logger.info "Forecast.mock_forecast: Successfully created forecast ID: #{forecast.id}"
        forecast
      else
        Rails.logger.error "Forecast.mock_forecast: Failed to save forecast: #{forecast.errors.full_messages.join(', ')}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Forecast.mock_forecast: Error creating forecast: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end
  
  # Check if the forecast is from cache and cache is still fresh
  # @return [Boolean] True if from cache and fresh
  def cache_fresh?
    Time.now - queried_at < self.class.cache_duration && Time.now - queried_at > 1.minute
  end
  
  # Get parsed forecast data
  # @return [Hash, nil] Parsed forecast data
  def forecast_data
    @forecast_data ||= ForecastParserService.parse(extended_forecast)
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

  private
  
  # Sample forecast data for testing
  def self.sample_forecast_data
    {
      current_weather: {
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
