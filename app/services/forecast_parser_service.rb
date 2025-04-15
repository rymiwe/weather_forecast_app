# frozen_string_literal: true

# Minimal ForecastParserService to support Forecast model methods
class ForecastParserService
  # Parses the extended forecast JSON/hash and returns it as a Ruby hash
  def self.parse(data)
    if data.is_a?(String)
      trimmed = data.strip
      if trimmed.start_with?('{', '[')
        begin
          JSON.parse(trimmed)
        rescue JSON::ParserError => e
          Rails.logger.error "ForecastParserService.parse: JSON parse error: #{e.message} | Raw input: #{trimmed.inspect}"
          nil
        end
      else
        Rails.logger.warn "ForecastParserService.parse: Input string does not look like JSON: #{trimmed.inspect}"
        nil
      end
    else
      data
    end
  end

  # Extracts daily forecasts from the parsed forecast data
  def self.extract_daily_forecasts(data)
    data && data['forecastday'] ? data['forecastday'] : []
  end

  # Extracts current weather from the parsed forecast data
  def self.extract_current_weather(data)
    data && data['current'] ? data['current'] : {}
  end
end
