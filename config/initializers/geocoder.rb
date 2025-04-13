Geocoder.configure(
  # Use Nominatim (OpenStreetMap) as the geocoding service - it's free and has good coverage
  lookup: :nominatim,
  
  # Use HTTPS for all geocoding requests
  use_https: true,
  
  # Set a reasonable timeout for geocoding requests
  timeout: 5,
  
  # Units for distance calculation
  units: :mi,
  
  # Cache geocoding results to reduce API calls
  cache: Rails.cache,
  cache_prefix: "geocoder:",
  
  # Set a proper user-agent as required by Nominatim's usage policy
  http_headers: { "User-Agent" => "WeatherForecastApp/1.0" },
  
  # In case of failure, return nil rather than raising an exception
  always_raise: [],
  
  # Rate limiting - be polite to the geocoding service
  # Nominatim's limit is 1 request per second
  api_key: nil,
  ip_lookup: :ipapi_com
)
