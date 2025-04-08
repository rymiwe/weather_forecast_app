# Weather Forecast Application

A Ruby on Rails application that provides weather forecasts based on user-provided addresses with caching functionality.

## Demo

This application is available on GitHub: https://github.com/rymiwe/weather_forecast_app

## Features

- Accept an address as input
- Retrieve and display current temperature
- Show high/low temperatures
- Display extended 5-day forecast
- Cache forecast data for 30 minutes by zip code
- Show indicator when results are pulled from cache
- Modern, responsive UI using Tailwind CSS

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

4. Configure API key:
   - Copy the example configuration file: `cp config/env.yml.example config/env.yml`
   - Edit `config/env.yml` and replace `your_api_key_here` with your OpenWeatherMap API key
   - You can get a free API key by:
     1. Register at https://home.openweathermap.org/users/sign_up
     2. After registering, go to your API keys section: https://home.openweathermap.org/api_keys
     3. Copy your API key (or create a new one)
   - Note: The application includes a mock weather service that works without an API key for development/testing

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

## Testing

Run the test suite with:

```
bin/rails test
```

The application includes comprehensive tests covering:
- Model validations and scopes
- Controller actions and responses
- Service layer functionality
- Integration tests for the complete user flow

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

The complete source code is available at: https://github.com/rymiwe/weather_forecast_app
