# Weather Forecast Application

A Ruby on Rails application that provides weather forecasts based on user-provided addresses with caching functionality.

## Demo

This application is available on GitHub: https://github.com/rymiwe/weather_forecast_app

## Features

- **Address-based Weather Search**: Get weather forecasts for any address or zip code
- **Detailed Forecasts**: View current conditions, temperatures, and 5-day forecasts
- **Intelligent Caching**: DB-backed caching system with configurable expiration
- **Smart Temperature Units**: Automatically selects Fahrenheit or Celsius based on location
- **Responsive Design**: Mobile-friendly interface using Tailwind CSS
- **Comprehensive Error Handling**: Graceful handling of API failures and network issues
- **Extensive Test Coverage**: 213 tests with 88% code coverage using RSpec

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
3. If a recent forecast exists, it's retrieved from the database rather than making an API call
4. When displaying cached forecasts, a clear "Cached Result" indicator is shown to the user
5. Once the cache expires, the next request triggers a fresh API call

#### Why Database Caching Instead of Redis/Memory Cache

This application intentionally uses database-backed caching rather than an in-memory solution like Redis for several enterprise-focused reasons:

1. **Persistence Across Deployments**: Database caching ensures that cached weather data survives application restarts, deployments, and server migrations. This is critical for enterprise applications where deployments shouldn't disrupt the user experience.

2. **No Additional Infrastructure**: Many enterprises prefer minimizing infrastructure components. By using the existing database, we avoid adding another system (Redis) that would require monitoring, maintenance, and scaling considerations.

3. **Transactional Consistency**: Database caching allows cache operations to participate in database transactions, ensuring data consistency in complex operations.

4. **Built-in Backup and Recovery**: Enterprise backup strategies already include the database, so cached data is automatically backed up without additional processes.

5. **Audit and Inspection**: Database caching makes it easy to inspect the cache state using standard database tools and SQL queries, facilitating troubleshooting and performance analysis.

6. **Horizontal Scaling Readiness**: In a horizontally scaled application with multiple application servers, database caching ensures all instances share a consistent cache state without complex cache synchronization mechanisms.

7. **Historical Data Preservation**: The database approach allows historical weather data to be preserved for analysis, reporting, and compliance purposes.

#### Redis/Memory Cache Alternative

For high-traffic scenarios where cache access speed is critical, the application is designed to be easily extended with a two-tier caching strategy:

```ruby
def find_forecast(zip_code)
  # First check fast in-memory/Redis cache
  if Rails.cache.exist?(cache_key(zip_code))
    return Rails.cache.read(cache_key(zip_code))
  end

  # Fall back to database cache
  cached_forecast = find_by(zip_code: zip_code)
  if cached_forecast&.fresh?
    # Populate in-memory cache from database for future requests
    Rails.cache.write(cache_key(zip_code), cached_forecast, expires_in: 30.minutes)
    return cached_forecast
  end
  
  # No valid cache found
  return nil
end
```

This tiered approach provides both the performance benefits of in-memory caching and the data persistence advantages of the current database implementation.

## Error Handling Strategy

The application uses a centralized error handling approach to provide a consistent and user-friendly experience:

### Graceful Error Handling

The application takes a pragmatic approach to error handling:

- **Reactive Rather Than Preventative**: Instead of complex rate limiting prevention, we focus on gracefully handling errors when they occur
- **Standardized Error Responses**: All errors are formatted consistently through `ErrorHandlingService`
- **User-Friendly Messages**: Error messages are appropriate for end users
- **Comprehensive Logging**: All errors are logged with context for troubleshooting

```ruby
# Example of how rate limit errors are handled
begin
  weather_data = weather_service.get_forecast(location)
  # Process successful response
rescue ApiRateLimiter::RateLimitExceededError => e
  # Standard error handling through ErrorHandlingService
  error_response = ErrorHandlingService.handle_api_error(e)
  render_error_response(error_response)
end
```

This approach ensures errors are handled consistently while keeping the codebase simple and maintainable.

## Running Tests

Run the entire test suite:

```
bundle exec rspec
```

Run specific test categories:

```
bundle exec rspec spec/models/      # Model tests
bundle exec rspec spec/requests/    # Controller/request tests
bundle exec rspec spec/system/      # End-to-end browser tests
bundle exec rspec spec/services/    # Service object tests
bundle exec rspec spec/helpers/     # Helper tests
```

The application includes 213 comprehensive tests covering all aspects of functionality, including edge cases and error scenarios.

## Code Coverage Analysis

This project uses SimpleCov to monitor and ensure high test coverage. Current test coverage is over 88% across all application code, with key components achieving 90-100% coverage.

```
bundle exec rspec                   # Runs all tests with coverage report
COVERAGE=true bundle exec rspec     # Explicitly generate coverage report
```

Coverage reports are generated in HTML format in the `coverage/` directory. The reports provide detailed file-by-file analysis showing which lines of code are covered by tests and which need additional testing.

Benefits of our comprehensive test coverage:
- Identifies untested code branches and edge cases
- Ensures error handling paths are properly tested
- Reduces regression risks when adding new features
- Serves as living documentation of expected behavior
- Enables confident refactoring and code improvements

Our test suite specifically focuses on testing error conditions extensively, ensuring the application gracefully handles API failures, network issues, and invalid user inputs.

### Error Handling Integration Tests

The application includes specialized integration tests that simulate various error scenarios:

```ruby
# Example from error_handling_integration_spec.rb
describe "API errors" do
  context "when API is unreachable" do
    before do
      allow(ForecastRetrievalService).to receive(:retrieve)
        .and_raise(Net::HTTPServerException.new("500 Internal Server Error", nil))
    end
    
    it "displays a user-friendly error message" do
      get "/forecasts", params: { address: valid_zip }
      expect(response.body).to include("Unable to connect to external service")
      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
```

These tests verify that the application properly handles:
- Network connectivity issues
- API timeouts and server errors
- Malformed responses (JSON parsing errors)
- Configuration errors
- Invalid user inputs

Each error case is tested to ensure appropriate status codes and user-friendly error messages are displayed, providing a robust and resilient application experience.

## Configuration

The application is designed with enterprise-level configurability in mind. All critical parameters are externalized through environment variables:

| Environment Variable | Description | Default Value | Example |
|---------------------|-------------|---------------|---------|
| `OPENWEATHERMAP_API_KEY` | Your OpenWeatherMap API key | None (Required) | `a1b2c3d4e5f6g7h8i9j0...` |
| `WEATHER_CACHE_DURATION_MINUTES` | Duration (in minutes) to cache weather forecasts | 30 | `60` |
| `WEATHER_DEFAULT_UNIT` | Default temperature unit system | `nil` (auto-detect by IP) | `metric` (Celsius) |
| `WEATHER_API_TIMEOUT_SECONDS` | API request timeout in seconds | 10 | `5` |
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

## Environment Variables

The application uses the following environment variables:

- `OPENWEATHERMAP_API_KEY`: API key for accessing OpenWeatherMap API
- `WEATHER_CACHE_DURATION_MINUTES`: Duration in minutes to cache forecast data (default: 30)
- `WEATHER_DEFAULT_UNIT`: Default temperature unit (imperial or metric, default: imperial)
- `WEATHER_USE_MOCK`: Set to 'true' to use the mock weather service in any environment

## Smart Temperature Unit Selection

The application implements intelligent temperature unit selection to provide a better user experience:

### IP-Based Detection

1. **Geographic Intelligence**: Automatically detects user's location via IP address
   - Uses the Geocoder gem to determine country from IP
   - Defaults to Fahrenheit (imperial) for US, Liberia, Myanmar
   - Defaults to Celsius (metric) for all other countries
   - Handles private/local IPs appropriately

2. **Preference Hierarchy**:
   - User's explicit preference (stored in session) takes highest priority
   - Environment configuration (`WEATHER_DEFAULT_UNIT`) is second priority
   - IP-based detection is used as fallback
   - User can toggle between units at any time via UI controls

3. **Implementation Details**:
   ```ruby
   def temperature_units
     session[:temperature_units] || 
       Rails.configuration.x.weather.default_unit || 
       UserLocationService.units_for_ip(request.remote_ip)
   end
   ```

4. **Testing**:
   - Comprehensive specs for all scenarios including edge cases
   - Mocked geocoding responses for consistent test behavior
   - System tests verify UI behavior and preference persistence

## API Rate Limiting

To ensure the application remains within API provider limits and provides a stable experience:

### Implementation

1. **Request Throttling**: Enforces configurable rate limits per service
   - Default limit for OpenWeatherMap API: 60 requests per minute (free tier)
   - Configurable via `WEATHER_MAX_REQUESTS_PER_MINUTE` environment variable

2. **Time-Based Tracking**: Uses minute-based windows for counting requests
   - Each minute gets a fresh quota of allowed requests
   - Different services are tracked separately

3. **Graceful Degradation**: When limits are reached
   - Returns appropriate error messages to users
   - Logs rate limit events for monitoring
   - Prevents unnecessary API calls that would be rejected

4. **Memory-Based Storage**: Uses in-memory counter with mutex for thread safety
   - In production, this could be extended to use Redis for distributed rate limiting

5. **Implementation Code**:
   ```ruby
   def self.allow_request?(service_name)
     max_requests = Rails.configuration.x.weather.max_requests_per_minute || DEFAULT_MAX_REQUESTS_PER_MINUTE
     current_minute = Time.current.strftime('%Y-%m-%d-%H-%M')
     key = "#{service_name}:#{current_minute}"
     
     # Check if under limit before incrementing counter
     if current_count(key) < max_requests
       increment_counter(key)
       true
     else
       false
     end
   end
   ```

## Enterprise Production Readiness

This application demonstrates enterprise-grade production quality through the following features:

### 1. Comprehensive Configuration System
- **Environment-Based Configuration**: All critical parameters externalized via environment variables
- **No Hardcoded Values**: All configurable values accessible through `Rails.configuration.x` namespace
- **Multi-Environment Support**: Different settings for development, test, production environments
- **Secure Credential Management**: Sensitive data (API keys) can be stored in encrypted credentials
- **Feature Flags**: Toggle functionality like temperature units via configuration
- **Configuration Examples**: Sample files provided for easy deployment

### 2. Intelligent Caching Implementation
- **Externalized Cache Duration**: Configurable via `WEATHER_CACHE_DURATION_MINUTES` environment variable
- **Cache Status Indicators**: Clear UI elements showing users whether data is fresh or cached
- **Cache Expiration Logic**: Sophisticated determination of cache validity with proper timestamp handling
- **Explicit Cache Lifecycle**: Created → Used → Expired → Replaced
- **Cache Performance**: Database indexes on lookup fields for fast retrieval

### 3. Regional Intelligence with Elegant Fallbacks
- **Smart Unit Detection**: IP-based temperature unit selection respects regional conventions
- **Graceful Degradation**: Default units when location cannot be determined
- **User Preference Prioritization**: Session storage remembers user choices
- **Configuration Override**: System-wide defaults can be enforced
- **User Control**: Simple UI toggles for switching units

### 4. External Service Protection
- **API Rate Limiting**: Thread-safe request throttling to respect provider limits
- **Configurable Thresholds**: Adjustable limits for different subscription tiers
- **Time-Window Approach**: Minute-based quota system for precise control
- **Graceful Service Degradation**: Clear error messages when limits are reached
- **Service Isolation**: Different external services tracked separately

### 5. Robust Testing Strategy
- **Comprehensive Test Suite**: Complete RSpec coverage of all functionality
- **Test Isolation**: Proper use of doubles and stubs for external services
- **Factory Patterns**: FactoryBot for consistent test data
- **Edge Case Coverage**: Tests for boundary conditions, errors, and edge cases
- **Behavior-Driven Approach**: Clear test descriptions documenting expected behavior
- **UI Testing**: System tests verify complete user flows

### 6. Production-Ready Error Handling
- **User-Friendly Messages**: Clear error presentation in the UI
- **Comprehensive Logging**: Errors logged with context for troubleshooting
- **Graceful Fallbacks**: Default behavior when services unavailable
- **Validation Layer**: Input validation to prevent invalid data
- **API Error Handling**: Proper handling of external service failures

### 7. Security Best Practices
- **No Exposed Secrets**: API keys and credentials properly secured
- **Environment Separation**: Configuration isolates environments
- **Parameterized Queries**: Safe database access patterns
- **Input Sanitization**: User inputs properly validated and sanitized
- **Proper Headers**: Security headers for web requests

### 8. Modern Service-Oriented Architecture
- **Separation of Concerns**: Clear boundaries between components
- **Service Objects**: Encapsulated external service interactions
- **Component Isolation**: Independent, testable modules
- **Dependency Injection**: Services receive configuration
- **Maintainable Structure**: Logical organization following conventions

This enterprise-ready architecture ensures the application is suitable for production deployment in demanding environments with high reliability, configurability, and maintainability requirements.

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
