# frozen_string_literal: true

# Service to parse and extract weather forecast data from JSON
class ForecastParserService
  # Parse a JSON string (or already parsed Hash)
  # @param [String, Hash] json JSON string or hash
  # @return [Hash, nil] Parsed forecast data
  def self.parse(json)
    return json if json.is_a?(Hash)
    return nil if json.blank?
    JSON.parse(json)
  rescue JSON::ParserError => e
    Rails.logger.error "ForecastParserService.parse: JSON parse error: #{e.message}"
    nil
  end

  # Extract daily forecasts from parsed data
  # @param [Hash] data Parsed forecast data
  # @return [Array<Hash>] Array of daily forecast hashes
  def self.extract_daily_forecasts(data)
    return [] unless data.is_a?(Hash)
    forecast_days = data.dig('forecast', 'forecastday')
    forecast_days.is_a?(Array) ? forecast_days : []
  end
end
