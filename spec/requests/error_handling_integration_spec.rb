# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Error Handling Integration", type: :request do
  let(:valid_zip) { "90210" }
  
  describe "API errors" do
    before do
      # Mock at the service level that's called directly by the controller
      allow(FindOrCreateForecastService).to receive(:call)
    end
    
    context "when API is unreachable" do
      before do
        allow(FindOrCreateForecastService).to receive(:call)
          .and_raise(ApiClientBase::ApiError.new("Unable to connect to weather service"))
      end
      
      it "displays a user-friendly error message" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("Unable to connect to weather service")
        expect(response).to have_http_status(:service_unavailable)
      end
    end
    
    context "when API times out" do
      before do
        allow(FindOrCreateForecastService).to receive(:call)
          .and_raise(ApiClientBase::ApiError.new("Request timed out"))
      end
      
      it "displays a timeout error message" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("Unable to connect to weather service")
        expect(response).to have_http_status(:service_unavailable)
      end
    end
    
    context "when API returns malformed JSON" do
      before do
        allow(FindOrCreateForecastService).to receive(:call)
          .and_raise(JSON::ParserError.new("Unexpected token"))
      end
      
      it "handles the JSON parsing error gracefully" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("Invalid response format")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    
    context "when API rate limit is exceeded" do
      before do
        allow(FindOrCreateForecastService).to receive(:call)
          .and_raise(ApiClientBase::RateLimitExceededError.new("Rate limit exceeded"))
      end
      
      it "displays a rate limit error message" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("Rate limit exceeded")
        expect(response).to have_http_status(:too_many_requests)
      end
    end
    
    context "when there's a configuration error" do
      before do
        allow(FindOrCreateForecastService).to receive(:call)
          .and_raise(ApiClientBase::ConfigurationError.new("Missing API key"))
      end
      
      it "displays a configuration error message" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("An error occurred")
        expect(response).to have_http_status(:internal_server_error)
      end
    end
    
    context "when there's a network connection error" do
      before do
        allow(FindOrCreateForecastService).to receive(:call)
          .and_raise(Errno::ECONNREFUSED.new("Connection refused"))
      end
      
      it "handles connection errors gracefully" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("An error occurred")
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
  
  describe "Invalid user inputs" do
    context "with empty address" do
      it "returns an error for empty address" do
        get "/forecasts", params: { address: "" }
        # Check for a validation error message
        expect(response.body).to include("Please provide an address")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    
    context "with invalid address format" do
      before do
        # Mock the service to simulate a processing error for invalid address
        allow(FindOrCreateForecastService).to receive(:call)
          .with(address: "not-a-valid-zip", request_ip: anything)
          .and_return(nil)
      end
      
      it "returns an error for invalid address format" do
        get "/forecasts", params: { address: "not-a-valid-zip" }
        expect(response.body).to include("Unable to find weather data")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe "Error recovery" do
    context "when a service recovers after failure" do
      it "handles successful requests after previous failures" do
        # First mock a failure
        allow(FindOrCreateForecastService).to receive(:call)
          .and_raise(ApiClientBase::ApiError.new("Request timed out"))
        
        get "/forecasts", params: { address: valid_zip }
        expect(response).to have_http_status(:service_unavailable)
        
        # Create sample extended forecast data
        extended_forecast_data = [
          { 'date' => '2025-04-10', 'day_name' => 'Thursday', 'high' => 29, 'low' => 18, 'conditions' => ['Sunny'] },
          { 'date' => '2025-04-11', 'day_name' => 'Friday', 'high' => 31, 'low' => 19, 
            'conditions' => ['Partly Cloudy'] },
          { 'date' => '2025-04-12', 'day_name' => 'Saturday', 'high' => 30, 'low' => 20, 'conditions' => ['Cloudy'] }
        ]
        
        # Then allow it to succeed with a complete mock object
        mock_forecast = double(
          'Forecast',
          id: 1,
          address: "Beverly Hills, CA 90210",
          zip_code: "90210",
          current_temp: 24,
          high_temp: 29,
          low_temp: 19,
          conditions: "Clear",
          extended_forecast: extended_forecast_data.to_json,
          extended_forecast_data: extended_forecast_data,
          cached?: false,
          queried_at: Time.now,
          display_units: 'metric'
        )
        
        # Reset the stub and make it return the mock forecast
        allow(FindOrCreateForecastService).to receive(:call)
          .and_return(mock_forecast)
        
        get "/forecasts", params: { address: valid_zip }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("90210")
      end
    end
  end
end
