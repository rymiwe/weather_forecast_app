class Forecast < ApplicationRecord
  # Validations
  validates :address, :current_temp, :queried_at, presence: true
  validates :zip_code, presence: true, uniqueness: { scope: :queried_at }
  
  # Scopes
  scope :recent, -> { where('queried_at >= ?', 30.minutes.ago).order(queried_at: :desc) }
  
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
  
  # Checks if the forecast data is from cache
  # @return [Boolean] True if data is from cache
  def cached?
    (Time.current - queried_at) > 1.minute
  end
  
  # Get extended forecast data as parsed JSON
  # @return [Array] Array of daily forecast data
  def extended_forecast_data
    return [] if extended_forecast.blank?
    
    JSON.parse(extended_forecast)
  rescue JSON::ParserError
    []
  end
end
