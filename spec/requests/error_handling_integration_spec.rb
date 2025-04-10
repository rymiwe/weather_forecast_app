require 'rails_helper'

RSpec.describe "Error Handling Integration", type: :request do
  let(:valid_zip) { "90210" }
  
  describe "API errors" do
    before do
      # Mock at the service level that's called directly by the controller
      allow(ForecastRetrievalService).to receive(:retrieve)
    end
    
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
    
    context "when API times out" do
      before do
        allow(ForecastRetrievalService).to receive(:retrieve)
          .and_raise(Timeout::Error.new("Request timed out"))
      end
      
      it "displays a timeout error message" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("Unable to connect to external service")
        expect(response).to have_http_status(:service_unavailable)
      end
    end
    
    context "when API returns malformed JSON" do
      before do
        allow(ForecastRetrievalService).to receive(:retrieve)
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
        allow(ForecastRetrievalService).to receive(:retrieve)
          .and_raise(ErrorHandlingService::RateLimitError.new("Rate limit exceeded"))
      end
      
      it "displays a rate limit error message" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("Rate limit exceeded")
        expect(response).to have_http_status(:too_many_requests)
      end
    end
    
    context "when there's a configuration error" do
      before do
        allow(ForecastRetrievalService).to receive(:retrieve)
          .and_raise(ErrorHandlingService::ConfigurationError.new("Missing API key"))
      end
      
      it "displays a configuration error message" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("Service configuration error")
        expect(response).to have_http_status(:service_unavailable)
      end
    end
    
    context "when there's a network connection error" do
      before do
        allow(ForecastRetrievalService).to receive(:retrieve)
          .and_raise(Errno::ECONNREFUSED.new("Connection refused"))
      end
      
      it "handles connection errors gracefully" do
        get "/forecasts", params: { address: valid_zip }
        expect(response.body).to include("Unable to connect to external service")
        expect(response).to have_http_status(:service_unavailable)
      end
    end
  end
  
  describe "Invalid user inputs" do
    context "with empty address" do
      it "returns an error for empty address" do
        get "/forecasts", params: { address: "" }
        # Check for a validation error message
        expect(response.body).to include("address")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    
    context "with invalid address format" do
      before do
        # Mock the zip code extraction to simulate a processing error
        allow(ZipCodeExtractionService).to receive(:extract_from_address)
          .with("not-a-valid-zip").and_return(nil)
          
        allow(ForecastRetrievalService).to receive(:retrieve)
          .and_raise(ArgumentError.new("Invalid address format"))
      end
      
      it "returns an error for invalid address format" do
        get "/forecasts", params: { address: "not-a-valid-zip" }
        expect(response.body).to include("Invalid")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe "Error recovery" do
    context "when a service recovers after failure" do
      it "handles successful requests after previous failures" do
        # First mock a failure - use any matcher for parameters
        allow(ForecastRetrievalService).to receive(:retrieve)
          .and_raise(Timeout::Error.new("Request timed out"))
        
        get "/forecasts", params: { address: valid_zip }
        expect(response).to have_http_status(:service_unavailable)
        
        # Create sample extended forecast data
        extended_forecast_data = [
          { 'date' => '2025-04-10', 'day_name' => 'Thursday', 'high' => 29, 'low' => 18, 'conditions' => ['Sunny'] },
          { 'date' => '2025-04-11', 'day_name' => 'Friday', 'high' => 31, 'low' => 19, 'conditions' => ['Partly Cloudy'] },
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
          queried_at: Time.now
        )
        
        # Add any additional methods the view might call
        allow(mock_forecast).to receive(:address_for_display).and_return("Beverly Hills, CA 90210")
        allow(mock_forecast).to receive(:cache_status).and_return("Fresh data")
        allow(mock_forecast).to receive(:persisted?).and_return(true)
        
        # Reset the stub and make it return the mock forecast
        allow(ForecastRetrievalService).to receive(:retrieve)
          .and_return(mock_forecast)
        
        get "/forecasts", params: { address: valid_zip }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("90210")
      end
    end
  end
end
