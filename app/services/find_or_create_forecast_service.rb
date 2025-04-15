# frozen_string_literal: true

# Service object to find or create a Forecast for a given address, using caching and API client
class FindOrCreateForecastService
  # Usage: FindOrCreateForecastService.call(address: ..., request_ip: ...)
  def self.call(address:, request_ip: nil)
    return nil if address.blank?

    normalized_address = address.to_s.strip.downcase
    Rails.logger.debug { "FindOrCreateForecastService: Normalized input: #{normalized_address}" }

    # Bias geocoding to US only for likely US ZIP codes
    geocoded = if normalized_address.match?(/^\d{5}(-\d{4})?$/)
                 Geocoder.search(normalized_address, params: { countrycodes: 'US' }).first
               else
                 Geocoder.search(normalized_address).first
               end
    unless geocoded&.latitude && geocoded.longitude
      Rails.logger.warn "FindOrCreateForecastService: Geocoding failed for address: #{normalized_address}"
      return nil
    end

    lat = geocoded.latitude.round(6)
    lon = geocoded.longitude.round(6)
    latlon_key = "#{lat},#{lon}"
    Rails.logger.debug do
      "FindOrCreateForecastService: Geocoded to lat: #{lat}, lon: #{lon}, latlon_key: #{latlon_key}"
    end
    Rails.configuration.x.weather.cache_ttl || 30.minutes

    # Try to fetch from cache by lat,lon (within 30 min)
    forecast = Forecast.where(address: latlon_key)
                       .where(queried_at: 30.minutes.ago..)
                       .order(queried_at: :desc).first
    Rails.logger.debug do
      "FindOrCreateForecastService: Cache lookup for #{latlon_key} => #{forecast.present? ? 'HIT' : 'MISS'}"
    end 
    from_cache = forecast.present?
    return forecast.tap { |f| f.from_cache = true } if from_cache

    # Fetch from Weather API client using lat,lon
    api_client = WeatherApiClient.instance
    forecast_data = api_client.get_weather(address: latlon_key)
    return nil unless forecast_data

    Rails.logger.debug { "FindOrCreateForecastService: Raw forecast_data from API: #{forecast_data.inspect}" }
    # Extract required temperature fields from forecast_data using symbol keys
    current_temp = forecast_data[:current]["temp_c"]
    high_temp = forecast_data[:forecast][:forecastday][0][:day][:maxtemp_c]
    low_temp = forecast_data[:forecast][:forecastday][0][:day][:mintemp_c]

    # Create and persist forecast record
    attrs = {
      address: latlon_key, # for cache lookup
      user_query: normalized_address, # store original input for display if desired (virtual attr or DB col)
      extended_forecast: forecast_data.to_json,
      queried_at: Time.current,
      from_cache: false,
      current_temp: current_temp,
      high_temp: high_temp,
      low_temp: low_temp
    }
    Rails.logger.debug { "FindOrCreateForecastService: Creating Forecast with attributes: #{attrs.inspect}" }
    forecast = Forecast.create(attrs)
    if forecast.persisted?
      Rails.logger.debug { "FindOrCreateForecastService: Forecast saved successfully with id #{forecast.id}" }
    else
      Rails.logger.error "FindOrCreateForecastService: Forecast failed to save: #{forecast.errors.full_messages.join(', ')}"
      raise "Forecast failed to save: #{forecast.errors.full_messages.join(', ')}"
    end
    forecast
  end
end
