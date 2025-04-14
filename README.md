# Weather Forecast Application

A Ruby on Rails 7 application that provides weather forecasts based on user-provided addresses with Redis-backed caching functionality.

![Weather Forecast App Screenshot](app/assets/images/screenshot.png)

## Features

- **Address-based Weather Search**: Get weather forecasts for any address or zip code
- **Detailed Forecasts**: View current conditions, temperatures, and 7-day forecasts
- **Intelligent Caching**: Redis-backed caching system with configurable expiration
- **Smart Temperature Units**: Automatically selects Fahrenheit or Celsius based on location
- **Responsive Design**: Mobile-friendly interface using Tailwind CSS
- **Hotwire/Turbo Integration**: Interactive UI updates without full page refreshes
- **ViewComponents**: Reusable UI components for consistent design
- **Comprehensive Error Handling**: Graceful handling of API failures and network issues
- **Simplified API Implementation**: Single-call weather retrieval with flexible location input

## Technical Stack

- Ruby 3.2.2
- Rails 7.1.5.1
- PostgreSQL database (production)
- SQLite (development/test)
- Redis for caching
- Tailwind CSS for styling
- Hotwire/Turbo for dynamic page updates
- Stimulus for JavaScript behaviors
- ViewComponents for modular UI
- WeatherAPI.com for weather data
- RSpec for testing

## Setup Instructions

### Prerequisites

- Ruby 3.2.2 or newer
- PostgreSQL (production)
- Redis (recommended for production)
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
   - Set the following environment variables:
     ```
     WEATHERAPI_KEY=your_api_key_here
     REDIS_URL=redis://localhost:6379/1 # Optional for development
     WEATHER_CACHE_TTL=30 # Cache time in minutes
     ```
   - You can get a free API key by:
     1. Register at https://www.weatherapi.com/
     2. After registering, go to your API keys section
     3. Copy your API key (or create a new one)

5. Start Redis (optional for development, required for production):
   ```
   # Using Docker:
   docker run --name redis -p 6379:6379 -d redis
   ```

6. Start the Rails server:
   ```
   bin/dev
   ```

7. Access the application at http://localhost:3000

## Deployment to Heroku

1. Create a new Heroku application:
   ```
   heroku create your-app-name
   ```

2. Add Redis to your application:
   ```
   heroku addons:create heroku-redis:hobby-dev
   ```

3. Configure environment variables:
   ```
   heroku config:set WEATHERAPI_KEY=your_api_key_here
   heroku config:set RAILS_MASTER_KEY=`cat config/master.key`
   heroku config:set WEATHER_CACHE_TTL=30
   ```

4. Deploy your application:
   ```
   git push heroku main
   ```

5. Run database migrations:
   ```
   heroku run rails db:migrate
   ```

## Caching Strategy

The application implements a multi-level caching strategy to minimize API calls and improve performance:

### 1. Redis Cache Implementation

The application uses Redis as the primary cache store in production, with a fallback to memory store in development:

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" },
  expires_in: ENV.fetch("WEATHER_CACHE_TTL", 30).to_i.minutes
}
```

### 2. Cache Key Structure

Cache keys are constructed to ensure uniqueness while maintaining consistency for identical locations:

```ruby
# Example cache key format
cache_key = "weather:#{normalized_address}"
```

The normalized address ensures that slight variations in user input (like "New York" vs "New York, NY") map to the same cache entry.

### 3. Cache TTL Strategy

- Default TTL is 30 minutes but is configurable via the `WEATHER_CACHE_TTL` environment variable
- Users can manually force a refresh via the UI for immediate updates
- API errors don't invalidate the cache, protecting against API downtime

## Hotwire/Turbo Implementation

The application leverages Rails 7's Hotwire/Turbo and Stimulus for a dynamic user experience:

### Turbo Frames

Search results are delivered via Turbo Frames, allowing for partial page updates without full-page reloads:

```erb
<%= turbo_frame_tag "forecast_results" do %>
  <%= render "forecast_content" if @forecast %>
<% end %>
```

### Stimulus Controllers

The application uses Stimulus controllers for interactive behaviors:

1. **Toggle Controller**: Handles expanding/collapsing the technical details section
2. **Search Form Controller**: Provides client-side validation with accessibility
3. **Weather Card Controller**: Manages dynamic card updates and interactions

## Testing Strategy

The application uses RSpec for comprehensive testing across all layers:

1. **Model Tests**: Test data relationships, validations, and business logic
2. **Request Specs**: Test API endpoints and controller actions
3. **System Tests**: Use Capybara for end-to-end testing of user workflows
4. **VCR Integration**: Records and plays back API responses to enable offline testing

Run the test suite with:

```
bundle exec rspec
```

## Architecture Best Practices

The application is built following these architectural best practices:

1. **MVC with Service Objects**: Core business logic is encapsulated in service objects
2. **ViewComponents**: UI components are isolated in ViewComponents for better testing and reuse
3. **Progressive Enhancement**: Basic functionality works without JavaScript, enhanced with Hotwire
4. **Separation of Concerns**: Styles in CSS, behavior in Stimulus controllers
5. **Comprehensive Testing**: Tests at multiple levels ensure code quality
6. **Database Optimization**: Proper indexing and query optimization
7. **Security Best Practices**: Strong parameters, input validation, and XSS protection
8. **Consistent DOM IDs**: Used throughout for Hotwire compatibility
9. **Accessible UI**: ARIA attributes, keyboard navigation, and screen reader support
10. **Performance Optimization**: Minimal frames, optimized controllers, responsive design

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
