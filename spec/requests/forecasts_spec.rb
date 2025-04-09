require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
  let(:api_key) { 'test_api_key' }
  let(:forecast) { create(:forecast) }
  
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
        current_temp: 52.5,
        high_temp: 58.0,
        low_temp: 48.0,
        conditions: "rainy",
        extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":55,"low":46,"conditions":["rain"]}]',
        queried_at: Time.current
      }
      
      # Using RSpec's built-in mocking
      allow_any_instance_of(MockWeatherService).to receive(:get_by_address)
        .with("Seattle, WA")
        .and_return(mock_data)
      
      # Act: Perform the request
      get forecasts_path, params: { address: "Seattle, WA" }
      
      # Assert: Verify response
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Seattle, WA 98101")
      expect(response.body).to include("53°F")  # Rounded from 52.5
      expect(response.body).to include("rain") 
    end
    
    it "uses cached forecast when forecast exists for zip code" do
      # Arrange: Create a cached forecast
      cached = create(:forecast, :chicago, queried_at: 15.minutes.ago)
      
      # Act: Search using the same zip code
      get forecasts_path, params: { address: "60601" }
      
      # Assert: Verify we get the cached result
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Chicago, IL 60601")
      expect(response.body).to include("Cached Result")
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
      allow_any_instance_of(MockWeatherService).to receive(:get_by_address)
        .with("Invalid location")
        .and_return({ error: "Invalid address" })
      
      # Act: Perform request with invalid address
      get forecasts_path, params: { address: "Invalid location" }
      
      # Assert: Verify error is shown
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Error retrieving forecast")
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
      # Act: Request forecast details
      get forecast_path(forecast)
      
      # Assert: Verify response has correct content
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Detailed Forecast")
      expect(response.body).to include(forecast.address)
      expect(response.body).to include("#{forecast.current_temp.round}°F")
      expect(response.body).to include("Back to Search")
      expect(response.body).to include("Technical Information")
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
