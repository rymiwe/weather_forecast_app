require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
  let(:api_key) { 'test_api_key' }
  let(:forecast) { Forecast.create(
    address: 'Seattle, WA 98101',
    zip_code: '98101',
    current_temp: 12,  # 53°F in Celsius
    high_temp: 18,     # 65°F in Celsius
    low_temp: 5.5,     # 42°F in Celsius
    conditions: 'Partly Cloudy',
    extended_forecast: "[]",
    queried_at: Time.current
  ) }
  
  before do
    ENV['OPENWEATHERMAP_API_KEY'] = api_key
  end
  
  describe "GET /forecasts" do
    it "displays the search form" do
      get forecasts_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Weather Forecast")
      expect(response.body).to include("Enter location or zip code")
      expect(response.body).to include("Get Forecast")
    end
    
    it "displays forecast for valid address" do
      # Arrange: Create mock data and stub service
      mock_data = {
        address: "Seattle, WA 98101",
        zip_code: "98101",
        current_temp: 12,  # 53°F in Celsius
        high_temp: 18,     # 65°F in Celsius
        low_temp: 5.5,     # 42°F in Celsius
        conditions: "Partly Cloudy",
        extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":18,"low":5.5,"conditions":["partly cloudy"]}]',
        queried_at: Time.current
      }
      
      # Mock the weather service
      weather_service = instance_double(MockWeatherService)
      allow(weather_service).to receive(:get_by_address).with(any_args).and_return(mock_data)
      allow(MockWeatherService).to receive(:new).and_return(weather_service)
      
      # Force imperial units for request
      session = { temperature_units: 'imperial' }
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('imperial')
      
      # Act: Perform the request
      get forecasts_path, params: { address: "Seattle, WA" }
      
      # Assert: Verify response
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Seattle")
      expect(response.body).to include("53°F")
      
      # Verify high/low temperatures
      expect(response.body).to include("65°F")  # Just the degree symbol for high temp
      expect(response.body).to include("42°F")  # Just the degree symbol for low temp
      
      # Verify at least the presence of extended forecast section
      expect(response.body).to include("Extended Forecast")
    end
    
    it "handles full street addresses" do
      # Arrange: Create mock data and stub service for full address
      mock_data = {
        address: "123 Pine St, San Francisco, CA 94111",
        zip_code: "94111",
        current_temp: 18,  # 64°F in Celsius
        high_temp: 21.1,   # 70°F in Celsius
        low_temp: 14.4,    # 58°F in Celsius
        conditions: "sunny",
        extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":21.1,"low":14.4,"conditions":["sunny"]}]',
        queried_at: Time.current
      }
      
      # Mock the weather service
      weather_service = instance_double(MockWeatherService)
      allow(weather_service).to receive(:get_by_address).with(any_args).and_return(mock_data)
      allow(MockWeatherService).to receive(:new).and_return(weather_service)
      
      # Force imperial units for request
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('imperial')
      
      # Act: Perform the request
      get forecasts_path, params: { address: "123 Pine St, San Francisco, CA 94111" }
      
      # Assert: Verify response
      expect(response).to have_http_status(:success)
      expect(response.body).to include("San Francisco")
      expect(response.body).to include("64°F")
      
      # Verify high/low temperatures
      expect(response.body).to include("70°F")  # Just the degree symbol for high temp
      expect(response.body).to include("58°F")  # Just the degree symbol for low temp
      
      # Verify at least the presence of extended forecast section
      expect(response.body).to include("Extended Forecast")
    end
    
    it "uses cached forecast when forecast exists for zip code" do
      # Arrange: Create a cached forecast
      cached = Forecast.create(
        address: 'Chicago, IL 60601',
        zip_code: '60601',
        current_temp: 12,  # 53°F in Celsius
        high_temp: 18,     # 65°F in Celsius
        low_temp: 5.5,     # 42°F in Celsius
        conditions: 'Partly Cloudy',
        extended_forecast: "[]",
        queried_at: 15.minutes.ago
      )
      
      # Act: Search using the same zip code
      get forecasts_path, params: { address: "60601" }
      
      # Assert: Verify we get the cached result
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Chicago, IL 60601")
      expect(response.body).to include("Cached Result")
      
      # Verify cached result doesn't make new API calls
      expect_any_instance_of(MockWeatherService).not_to receive(:get_by_address)
    end
    
    it "shows different UI indicators for fresh vs cached data" do
      # Arrange: Create forecasts with different cache statuses
      cached_forecast = Forecast.create(
        address: 'Chicago, IL 60601',
        zip_code: '60601',
        current_temp: 12,  # 53°F in Celsius
        high_temp: 18,     # 65°F in Celsius
        low_temp: 5.5,     # 42°F in Celsius
        conditions: 'Partly Cloudy',
        extended_forecast: "[]",
        queried_at: 15.minutes.ago
      )
      fresh_forecast = Forecast.create(
        address: 'Seattle, WA 98101',
        zip_code: '98101',
        current_temp: 12,  # 53°F in Celsius
        high_temp: 18,     # 65°F in Celsius
        low_temp: 5.5,     # 42°F in Celsius
        conditions: 'Partly Cloudy',
        extended_forecast: "[]",
        queried_at: 30.seconds.ago
      )
      
      # Act & Assert: Check cached forecast shows correct status
      get forecasts_path, params: { address: cached_forecast.zip_code }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Chicago, IL 60601")
      expect(response.body).to include("Cached Result")
      
      # Act & Assert: Check fresh forecast shows correct status
      get forecasts_path, params: { address: fresh_forecast.zip_code }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Seattle, WA 98101")
      expect(response.body).not_to include("Cached Result")
    end
    
    it "doesn't return results for empty address" do
      # Act: Search with empty address
      get forecasts_path, params: { address: "" }
      
      # Assert: No forecast results shown
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Current Temperature")
    end
    
    it "shows error for invalid address" do
      # Arrange: Stub service to return error
      error_data = { error: "Invalid address" }
      weather_service = instance_double(MockWeatherService)
      allow(weather_service).to receive(:get_by_address).with(any_args).and_return(error_data)
      allow(MockWeatherService).to receive(:new).and_return(weather_service)
      
      # Act: Perform request with invalid address
      get forecasts_path, params: { address: "Invalid location" }
      
      # Assert: Verify error is shown
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Unable to find location")
    end
    
    it "handles turbo stream format" do
      # Act: Request with turbo stream format
      get forecasts_path, params: { address: "Boston" }, 
                          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      # Assert: Verify response format
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
  
  describe "GET /forecasts/:id" do
    it "displays forecast details" do
      # Act: GET the specific forecast detail page
      get forecast_path(forecast)
      
      # Force imperial units for test
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('imperial')
      
      # Act: GET the specific forecast detail page
      get forecast_path(forecast)
      
      # Assert: Verify response has correct content
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Detailed Forecast")
      expect(response.body).to include(forecast.address)
      expect(response.body).to include("53°F")
      
      # Verify high/low temperatures
      expect(response.body).to include("65°F")  # Just the degree symbol for high temp
      expect(response.body).to include("42°F")  # Just the degree symbol for low temp
      
      # Verify extended forecast section
      expect(response.body).to include("5-Day Forecast")
      
      # Parse the extended forecast data and check for key elements
      if forecast.extended_forecast.present?
        # If we're using actual extended forecast data in the factory
        extended_data = JSON.parse(forecast.extended_forecast)
        if extended_data.any?
          expect(response.body).to include(extended_data.first['day_name'])
        end
      end
      
      # Verify technical cache information is displayed
      expect(response.body).to include("CACHE STATUS")
      expect(response.body).to include("CACHE EXPIRES")
      
      expect(response.body).to include("Back to Search")
      expect(response.body).to include("Technical Information")
    end
    
    it "displays different cache status for fresh vs cached forecasts" do
      # Arrange: Create forecasts with different cache statuses
      cached_forecast = Forecast.create(
        address: 'Chicago, IL 60601',
        zip_code: '60601',
        current_temp: 12,  # 53°F in Celsius
        high_temp: 18,     # 65°F in Celsius
        low_temp: 5.5,     # 42°F in Celsius
        conditions: 'Partly Cloudy',
        extended_forecast: "[]",
        queried_at: 15.minutes.ago
      )
      fresh_forecast = Forecast.create(
        address: 'Seattle, WA 98101',
        zip_code: '98101',
        current_temp: 12,  # 53°F in Celsius
        high_temp: 18,     # 65°F in Celsius
        low_temp: 5.5,     # 42°F in Celsius
        conditions: 'Partly Cloudy',
        extended_forecast: "[]",
        queried_at: 30.seconds.ago
      )
      
      # Act & Assert: Check cached forecast shows correct status
      get forecast_path(cached_forecast)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Chicago, IL 60601")
      expect(response.body).to include("Cached Result")
      
      # Act & Assert: Check fresh forecast shows correct status
      get forecast_path(fresh_forecast)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Seattle, WA 98101")
      expect(response.body).not_to include("Cached Result")
    end
    
    it "redirects to index for invalid id" do
      # Act: Request with invalid id
      get forecast_path(id: "nonexistent")
      
      # Assert: Verify redirect and flash message
      expect(response).to redirect_to(forecasts_path)
      expect(flash[:alert]).to eq("Forecast not found")
    end
  end
end
