# Deprecated Components

This document lists components that are no longer used in the main application but are kept for reference or test compatibility.

## Legacy Weather Services

The following services are deprecated and will be removed in a future release:

- `app/services/weather_service.rb` - Legacy OpenWeatherMap service
- `app/clients/open_weather_map_client.rb` - Legacy OpenWeatherMap client
- `app/clients/mock_open_weather_map_client.rb` - Mock version for testing

## Active Weather Services

The application now exclusively uses:

- `app/clients/weather_api_client.rb` - WeatherAPI.com client for all weather data
- `app/clients/mock_weather_api_client.rb` - Mock version for testing

## Environment Variables

Required environment variables:
- `WEATHERAPI_KEY` - Your WeatherAPI.com API key

Deprecated environment variables (no longer needed):
- `OPENWEATHERMAP_API_KEY` - Legacy API key
