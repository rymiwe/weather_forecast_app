# Weather Forecast Application

A Ruby on Rails application that provides weather forecasts based on user-provided addresses with caching functionality.

## Demo

This application is available on GitHub: https://github.com/rymiwe/weather_forecast_app

## Features

- Accept an address as input (city name, ZIP code, or full street address)
- Retrieve and display current temperature
- Show high/low temperatures
- Display extended 5-day forecast
- Configurable caching mechanism with default 30-minute duration
- Show indicator when results are pulled from cache
- Modern, responsive UI using Tailwind CSS
- Enterprise-ready configuration through environment variables

## Technical Stack

- Ruby 3.0.6
- Rails 7.1.5.1
- PostgreSQL database
- Tailwind CSS for styling
- Hotwire/Turbo for dynamic page updates
- OpenWeatherMap API for weather data

## Setup Instructions

### Prerequisites

- Ruby 3.0.6 or newer (managed via asdf)
- PostgreSQL
- Node.js and Yarn (for Tailwind CSS)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/rymiwe/weather_forecast_app.git
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
   - Edit `config/env.yml` and replace `your_api_key_here` with your OpenWeatherMap API key
   - You can get a free API key by:
     1. Register at https://home.openweathermap.org/users/sign_up
     2. After registering, go to your API keys section: https://home.openweathermap.org/api_keys
     3. Copy your API key (or create a new one)
   - Note: The application includes a mock weather service that works without an API key for development/testing
   - Configure other environment variables as needed (see Configuration section below)

5. Load sample data (optional):
   ```
   bin/rails db:seed
   ```
   This loads sample weather data for demonstration purposes.

6. Start the Rails server:
   ```
   bin/dev
   ```

7. Access the application at http://localhost:3000

## Using the Application

1. Enter an address or zip code in the search field
2. Click "Get Forecast" to retrieve the weather information
3. View current temperature, high/low, and the 5-day forecast
4. Note: If you search for a location with the same zip code within 30 minutes, you'll see a "Cached Result" indicator

## System Architecture

### Object Decomposition

#### Models
- `Forecast`: Stores forecast data including temperatures, conditions, and caching metadata
  - Responsible for maintaining the data structure and cache validation logic
  - Contains methods for determining if data is from cache

#### Controllers
- `ForecastsController`: Handles user requests and displays forecasts
  - Manages the flow between user input, data retrieval, and view rendering
  - Contains caching logic to optimize API usage

#### Services
- `WeatherService`: Interfaces with the OpenWeatherMap API
  - Abstracts API interaction details away from the controller
  - Handles data transformation from API responses to application model format

### Design Patterns

1. **Service Objects Pattern**
   - Used for the `WeatherService` to encapsulate external API interactions
   - Keeps controllers thin and focused on request/response handling

2. **MVC Architecture**
   - Clear separation of concerns between models, views, and controllers
   - Model (Forecast) handles data storage and validation
   - View templates handle presentation logic
   - Controller coordinates interaction between models and views

3. **Repository Pattern**
   - The Forecast model acts as a repository for weather data
   - Provides methods to find cached data or create new entries

4. **Caching Strategy**
   - Implementation of 30-minute data caching by zip code
   - Cache indicator pattern to inform users when data is from cache

### Caching Implementation

The application implements a database-backed caching mechanism:

1. When a user submits an address, the system attempts to extract a zip code
2. If a valid zip code is found, the system checks for a recent (< 30 minutes old) forecast
3. If a cached forecast exists, it is displayed with a "Cached Result" indicator
4. If no cache exists, the system fetches fresh data from the OpenWeatherMap API
5. All weather data is saved with a timestamp for cache expiration calculation

### Caching Strategy Details

The application implements a **database-backed caching** mechanism:

#### Current Implementation

- Weather forecast data is stored in the PostgreSQL database
- The `forecasts` table stores complete forecast records with ZIP code as a lookup key
- Records include a `queried_at` timestamp used to determine cache freshness
- The configurable cache duration (`WEATHER_CACHE_DURATION_MINUTES`) determines how long forecasts are considered valid
- A database query using a time-based scope identifies valid cached entries:
  ```ruby
  scope :recent, -> { where('queried_at >= ?', Rails.configuration.x.weather.cache_duration.ago).order(queried_at: :desc) }
  ```

#### Advantages of Database Caching

- **Simplicity**: No additional infrastructure requirements beyond the existing database
- **Persistence**: Cached data survives application restarts and deployments
- **Data Retention**: Historical weather data remains available for analysis and reporting
- **Transactional Integrity**: Cache operations participate in database transactions
- **Admin Visibility**: Cache state is easily inspectable via standard database tools

#### Enterprise Scalability Considerations

For high-traffic enterprise deployments, consider implementing a multi-tiered caching strategy:

1. **L1 Cache (Memory)**: Add Rails.cache with Redis/Memcached as the cache store
   ```ruby
   # Example implementation in config/environments/production.rb
   config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
   ```

2. **L2 Cache (Database)**: Retain the current implementation as a fallback
   ```ruby
   # First check memory cache, then database cache
   def self.find_by_zip(zip_code)
     Rails.cache.fetch("forecast/#{zip_code}", expires_in: Rails.configuration.x.weather.cache_duration) do
       find_cached(zip_code) || fetch_and_save_forecast(zip_code)
     end
   end
   ```

3. **Cache Cleanup**: Add a background job to remove stale forecast records
   ```ruby
   # Example job that could run daily
   class StaleDataCleanupJob < ApplicationJob
     def perform
       Forecast.where('queried_at < ?', 1.week.ago).delete_all
     end
   end
   ```

This tiered approach provides both the performance benefits of in-memory caching and the data persistence advantages of the current database implementation.

## Configuration

The application is designed with enterprise-level configurability in mind. All critical parameters are externalized through environment variables:

| Environment Variable | Description | Default Value | Example |
|---------------------|-------------|---------------|---------|
| `OPENWEATHERMAP_API_KEY` | Your OpenWeatherMap API key | None (Required) | `a1b2c3d4e5f6g7h8i9j0...` |
| `WEATHER_CACHE_DURATION_MINUTES` | Duration (in minutes) to cache weather forecasts | 30 | `60` |
| `WEATHER_DEFAULT_UNIT` | Default temperature unit system | `imperial` (Fahrenheit) | `metric` (Celsius) |
| `WEATHER_API_TIMEOUT_SECONDS` | API request timeout in seconds | 10 | `5` |
| `WEATHER_MAX_REQUESTS_PER_MINUTE` | Maximum API requests per minute | 60 | `30` |
| `WEATHER_FORECAST_DAYS` | Number of days in extended forecast | 5 | `7` |
| `WEATHER_API_LOG_LEVEL` | Log level for API interactions | `info` | `debug` |

### Configuration Methods

You can set these variables using any of these methods (in order of precedence):

1. **Environment variables** directly in your deployment environment
   ```
   export OPENWEATHERMAP_API_KEY=your_api_key_here
   export WEATHER_CACHE_DURATION_MINUTES=45
   ```

2. **config/env.yml file** (included in .gitignore to prevent sensitive data exposure)
   ```yaml
   OPENWEATHERMAP_API_KEY: 'your_api_key_here'
   WEATHER_CACHE_DURATION_MINUTES: 45
   ```

3. **Rails credentials** (encrypted, suitable for production)
   ```
   rails credentials:edit
   ```
   Add to the credentials file:
   ```yaml
   openweathermap_api_key: your_api_key_here
   weather:
     cache_duration_minutes: 45
   ```

### Extending Configuration

For adding new configurable parameters, follow this pattern in `config/application.rb`:

```ruby
# Application specific configuration
config.x.weather = ActiveSupport::InheritableOptions.new
config.x.weather.cache_duration = ENV.fetch('WEATHER_CACHE_DURATION_MINUTES', 30).to_i.minutes
```

## Testing

Run the test suite with:

```
bundle exec rspec
```

The application includes comprehensive RSpec tests covering:
- Model validations, scopes and methods
- Request specs for controller actions
- Service layer functionality
- System tests for complete user flows
- Test coverage for configurable parameters

## Scalability Considerations

- **API Request Management**: Implements caching to reduce API calls and stay within rate limits
- **Database Optimization**: Uses proper indexing on the zip_code and queried_at fields for fast cache lookups
- **Performance**: Minimizes database queries and optimizes view rendering
- **Error Handling**: Robust error handling for API failures and invalid user inputs
- **Future Expansion**: Modular design allows for easy addition of new features or data sources

## Best Practices Implemented

- **Clean Code**: Well-organized, readable code with proper naming conventions
- **DRY Principles**: Avoid code duplication through proper abstraction
- **Comprehensive Documentation**: Detailed inline comments and external documentation
- **Error Handling**: Robust error handling throughout the application
- **Responsive Design**: Mobile-friendly UI using Tailwind CSS
- **Modern Web Standards**: Uses Hotwire/Turbo for seamless page updates without full refreshes

## Project Structure

```
weather_forecast_app/
├── app/
│   ├── controllers/
│   │   └── forecasts_controller.rb  # Handles forecast requests
│   ├── models/
│   │   └── forecast.rb              # Forecast data model with caching
│   ├── services/
│   │   └── weather_service.rb       # OpenWeatherMap API integration
│   │   └── mock_weather_service.rb  # Mock service for development/testing
│   └── views/
│       └── forecasts/               # Forecast views with Tailwind styling
├── config/
│   ├── env.yml.example              # Example environment configuration (template)
│   └── env.yml                      # Your API key configuration (not in git)
├── db/
│   ├── migrate/                     # Database migration files
│   └── seeds.rb                     # Sample forecast data
└── test/
    ├── models/                      # Model tests
    ├── controllers/                 # Controller tests
    └── system/                      # End-to-end tests
```

## Submission Information

This project was created as part of a coding challenge with the following requirements:
- Ruby on Rails implementation
- Address input for weather forecasts
- Current temperature and extended forecast display
- 30-minute caching by zip code with indicators
- Clean, maintainable code with proper documentation
- Configurable caching mechanism with environment variable control
- Clean, maintainable code with enterprise-level configuration
- Thorough RSpec test coverage including cache testing

The complete source code is available at: https://github.com/rymiwe/weather_forecast_app
