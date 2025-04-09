require 'rails_helper'

RSpec.describe "Weather Forecasts", type: :system do
  before do
    # Set up environment with API key
    ENV['OPENWEATHERMAP_API_KEY'] = 'test_api_key'
    
    # Set up stubbing for the MockWeatherService
    allow_any_instance_of(MockWeatherService).to receive(:get_by_address).and_call_original
  end

  describe "Visiting the home page" do
    it "displays the search form" do
      # Visit the homepage
      visit root_path
      
      # Check that the page has the correct title and elements
      expect(page).to have_content("Weather Forecast")
      expect(page).to have_field("address")
      expect(page).to have_button("Get Forecast")
    end
  end
  
  describe "Searching for a forecast" do
    it "displays weather data for a valid location" do
      # Mock data for Seattle
      seattle_data = {
        address: "Seattle, WA 98101",
        zip_code: "98101",
        current_temp: 52.5,
        high_temp: 58.0,
        low_temp: 48.0,
        conditions: "partly cloudy",
        extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":55,"low":46,"conditions":["partly cloudy"]}]',
        queried_at: Time.current
      }
      
      # Stub the service to return our mock data
      allow_any_instance_of(MockWeatherService).to receive(:get_by_address)
        .with("Seattle, WA")
        .and_return(seattle_data)
      
      # Visit the homepage and search
      visit root_path
      fill_in "address", with: "Seattle, WA"
      click_button "Get Forecast"
      
      # Verify results are displayed
      expect(page).to have_content("Seattle, WA 98101")
      expect(page).to have_content("53°F") # Rounded from 52.5
      expect(page).to have_link("View Details")
    end
    
    it "shows an error message for invalid location" do
      # Stub the service to return an error
      allow_any_instance_of(MockWeatherService).to receive(:get_by_address)
        .with("Invalid Location")
        .and_return({ error: "Could not geocode address" })
      
      # Visit the homepage and search
      visit root_path
      fill_in "address", with: "Invalid Location"
      click_button "Get Forecast"
      
      # When an error occurs, we stay on the search page and no results are shown
      expect(page).to have_current_path(root_path, ignore_query: true)
      expect(page).not_to have_content("Current Temperature")
    end
    
    it "uses cached data when available" do
      # Create a cached forecast
      cached_forecast = create(:forecast, :chicago, queried_at: 15.minutes.ago)
      
      # Visit the homepage and search
      visit root_path
      fill_in "address", with: cached_forecast.zip_code
      click_button "Get Forecast"
      
      # Verify cached results are displayed
      expect(page).to have_content(cached_forecast.address)
      expect(page).to have_content("Cached Result")
    end
  end
  
  describe "Viewing forecast details" do
    let(:forecast) { create(:forecast) }
    
    it "displays detailed forecast information" do
      # Visit the details page
      visit forecast_path(forecast)
      
      # Verify forecast details are displayed
      expect(page).to have_content("Detailed Forecast")
      expect(page).to have_content(forecast.address)
      expect(page).to have_content("#{forecast.current_temp.round}°F")
      
      # Check for the high and low temperatures in the format they appear
      expect(page).to have_content("#{forecast.high_temp.round}°")
      expect(page).to have_content("#{forecast.low_temp.round}°")
      
      # Verify other elements
      expect(page).to have_content("Technical Information")
      expect(page).to have_content("FORECAST ID")
      
      # Verify navigation
      expect(page).to have_link("Back to Search")
    end
    
    it "redirects to index if forecast not found" do
      # Visit a non-existent forecast
      visit forecast_path(id: 999999)
      
      # Verify we're redirected with an alert
      expect(page).to have_current_path(forecasts_path)
      expect(page).to have_content("Forecast not found")
    end
  end
  
  describe "End-to-end flow" do
    it "allows searching and viewing details", js: true do
      # Mock data for New York
      ny_data = {
        address: "New York, NY 10001",
        zip_code: "10001",
        current_temp: 62.0,
        high_temp: 68.0,
        low_temp: 55.0,
        conditions: "sunny",
        extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":65,"low":54,"conditions":["sunny"]}]',
        queried_at: Time.current
      }
      
      # Create a stub that returns our mock data and saves a real record
      allow_any_instance_of(MockWeatherService).to receive(:get_by_address)
        .with("New York")
        .and_return(ny_data)
      
      # Start the flow
      visit root_path
      fill_in "address", with: "New York"
      click_button "Get Forecast"
      
      # Verify results are displayed
      expect(page).to have_content("New York, NY 10001")
      
      # Click through to details
      click_link "View Details"
      
      # Verify we're on the details page
      expect(page).to have_content("Detailed Forecast")
      expect(page).to have_content("New York, NY 10001")
      
      # Go back to search
      click_link "Back to Search"
      
      # Verify we're back on the search page
      expect(page).to have_current_path(forecasts_path)
      expect(page).to have_field("address")
    end
  end
end
