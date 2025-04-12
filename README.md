# Weather Forecast Application

A Ruby on Rails 7 application that provides weather forecasts based on user-provided addresses with Redis-backed caching functionality.

![Weather Forecast App Screenshot](app/assets/images/screenshot.png)

## Features

- **Address-based Weather Search**: Get weather forecasts for any address or zip code
- **Detailed Forecasts**: View current conditions, temperatures, and 5-day forecasts
- **Intelligent Caching**: Redis-backed caching system with configurable expiration
- **Smart Temperature Units**: Automatically selects Fahrenheit or Celsius based on location
- **Responsive Design**: Mobile-friendly interface using Tailwind CSS
- **Hotwire/Turbo Integration**: Interactive UI updates without full page refreshes
- **ViewComponents**: Reusable UI components for consistent design
- **Comprehensive Error Handling**: Graceful handling of API failures and network issues
- **Simplified API Implementation**: Single-call weather retrieval with flexible location input

## Technical Stack

- Ruby 3.0.6
- Rails 7.1.5.1
- PostgreSQL database
- Redis for caching
- Tailwind CSS for styling
- Hotwire/Turbo for dynamic page updates
- ViewComponents for modular UI
- WeatherAPI.com for weather data

## Setup Instructions

### Prerequisites

- Ruby 3.0.6 or newer
- PostgreSQL
- Redis (optional, falls back to memory store)
- Node.js and Yarn (for Tailwind CSS)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/example/weather_forecast_app.git
   cd weather_forecast_app
   ```

2. Install dependencies:
   ```
   bundle install
   yarn install
   ```

3. Setup the database:
   ```
   bin/rails db:create db:migrate
   ```

4. Configure API key and application settings:
   - Copy the example configuration file: `cp config/env.yml.example config/env.yml`
   - Edit `config/env.yml` and replace `your_api_key_here` with your WeatherAPI.com API key
   - You can get a free API key by:
     1. Register at https://www.weatherapi.com/
     2. After registering, go to your API keys section
     3. Copy your API key (or create a new one)

5. Start Redis (optional):
   ```
   # On Windows (WSL or Docker recommended)
   # Using Docker:
   docker run --name redis -p 6379:6379 -d redis
   
   # Set environment variable
   $env:REDIS_URL = "redis://localhost:6379/1"
   ```

6. Start the Rails server:
   ```
   bin/dev
   ```

7. Access the application at http://localhost:3000

## Caching Implementation

The application uses a multi-level caching strategy:

### 1. Database caching

- Weather data is stored in the database with timestamped queries
- The `Forecast` model includes methods to determine if data is fresh or stale
- This provides persistence across application restarts

### 2. Redis caching

- In production, Redis is used as the primary cache store
- Cache keys are structured as `weather_forecast:#{zip_code}`
- Cache duration is configurable via `WEATHER_CACHE_DURATION_MINUTES` environment variable

Example Redis cache configuration:

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, { 
  url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' },
  namespace: 'weather_app',
  expires_in: Rails.configuration.x.weather.cache_duration
}
```

### 3. Memory fallback

- The application gracefully falls back to memory cache if Redis is unavailable
- This ensures the application works in development without Redis

```ruby
# config/environments/development.rb
if ENV['REDIS_URL'].present?
  config.cache_store = :redis_cache_store, { 
    url: ENV['REDIS_URL'],
    namespace: "weather_app_dev",
    expires_in: Rails.configuration.weather_cache_duration
  }
else
  config.cache_store = :memory_store, { size: 64.megabytes }
end
```

## Application Architecture

### MVC and Service Objects

The application follows Rails MVC architecture with additional patterns:

1. **Models**: Handle data storage, validation, and business logic
2. **Views**: Use ViewComponents for reusable UI elements
3. **Controllers**: Coordinate requests and delegate complex operations to services
4. **Service Objects**: Handle complex business logic and external API interactions

Example service object pattern:

```ruby
# app/services/find_or_create_forecast_service.rb
class FindOrCreateForecastService < ServiceBase
  def initialize(address:, request_ip:)
    @address = address
    @request_ip = request_ip
  end
  
  def call
    # Service implementation
  end
end

# Using the service:
forecast = FindOrCreateForecastService.call(address: params[:address], request_ip: request.remote_ip)
```

### ViewComponents

UI elements are encapsulated in ViewComponents for reusability and testability:

```ruby
# app/components/weather_card_component.rb
class WeatherCardComponent < ViewComponent::Base
  def initialize(forecast:, units:, day_data: nil)
    @forecast = forecast
    @units = units
    @day_data = day_data
  end
  
  # Component methods
end

# In views:
<%= render WeatherCardComponent.new(forecast: @forecast, units: @units) %>
```

### Hotwire/Turbo Integration

The application uses Turbo Frames and Streams for dynamic updates without full page refreshes:

```erb
<turbo-frame id="<%= dom_id(@forecast) %>_current">
  <!-- Frame content -->
</turbo-frame>
```

## Rails 7 Best Practices

This application follows these Rails 7 best practices:

1. **MVC with Service Objects**: Models, controllers, and views have clear responsibilities; complex logic is extracted to service objects.

2. **ViewComponents for UI**: Reusable UI elements are encapsulated in ViewComponents, improving organization and testability.

3. **Standard Rails with Hotwire**: The application builds on standard Rails patterns, enhanced with Hotwire for dynamic interactions.

4. **No Inline Styles/Scripts**: All styling is in Tailwind classes, with JavaScript in Stimulus controllers.

5. **Comprehensive Testing**: Models, controllers, services, and ViewComponents have thorough test coverage.

6. **Optimized Database Queries**: Uses eager loading and proper indexing for efficient data access.

7. **Security Best Practices**: Implements strong parameters, CSRF protection, and secure API handling.

8. **dom_id for Hotwire**: Uses `dom_id` helpers for consistent HTML IDs in Turbo frames.

9. **Structured Turbo Frames**: Carefully designed frame hierarchy for targeted updates.

10. **Tailwind Best Practices**: Uses component classes for consistency and maintainability.

11. **Accessibility Support**: Implements proper ARIA attributes and manages focus for dynamic updates.

12. **Performance Optimization**: Minimizes database queries, uses Redis caching, and optimizes asset delivery.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `REDIS_URL` | Redis connection URL | `redis://localhost:6379/1` |
| `WEATHER_CACHE_DURATION_MINUTES` | Weather cache duration in minutes | `30` |
| `WEATHERAPI_KEY` | WeatherAPI.com API key | None (Required) |
| `OPENWEATHERMAP_API_KEY` | OpenWeatherMap API key (Legacy) | None (Optional) |
| `USE_MOCK_WEATHER_CLIENT` | Use mock data for development/testing | `false` |

## Weather API Implementation

The application uses WeatherAPI.com as the weather data provider, which offers several advantages:

1. **Single API Call**: Weather data is retrieved with a single API call that handles both location resolution and weather data retrieval, simplifying the implementation.

2. **Flexible Location Input**: The API accepts various location formats including city names, zip codes, and coordinates without requiring separate geocoding.

3. **Consistent Results**: Location inputs are normalized, ensuring consistent results regardless of case or format (e.g., "portland, or" and "Portland, OR" yield the same results).

4. **Comprehensive Data**: Includes current conditions, forecasts, and astronomical data in a single response.

5. **Generous Free Tier**: The free tier includes 1,000,000 calls per month, more than adequate for development and small production deployments.

The implementation follows a clean separation of concerns:
- `WeatherApiClient` handles the API integration with simple, focused methods
- `MockWeatherApiClient` provides deterministic test data
- `FindOrCreateForecastService` orchestrates the data retrieval and storage

## Running Tests

```
bundle exec rspec
