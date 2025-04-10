# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForecastRetrievalService do
  let(:address) { "123 Main St, Seattle, WA 98101" }
  let(:units) { "imperial" }
  let(:ip_address) { "192.168.1.1" }
  
  describe ".retrieve" do
    context "when forecast is in cache" do
      it "returns cached forecast when available" do
        # Create a cached forecast
        zip_code = "98101"
        cached_forecast = create(:forecast, zip_code: zip_code, queried_at: 1.minute.ago)
        
        # Mock the ZipCodeExtractionService service
        allow(ZipCodeExtractionService).to receive(:extract_from_address)
          .with(address).and_return(zip_code)
        
        # Verify the service returns the cached forecast
        result = ForecastRetrievalService.retrieve(address, units: units)
        expect(result).to eq(cached_forecast)
      end
    end
    
    context "when forecast is not in cache" do
      before do
        # Mock ZipCodeExtractionService service
        allow(ZipCodeExtractionService).to receive(:extract_from_address)
          .with(address).and_return("98101")
        
        # Enable API calls
        allow(ApiRateLimiter).to receive(:allow_request?).and_return(true)
        allow(ENV).to receive(:[]).with('OPENWEATHERMAP_API_KEY').and_return('test_key')
      end
      
      it "fetches from API when not in cache", pending: "Test needs to be updated for integer temperature storage" do
        address = "123 Main St, New York, NY 10001"
        zip_code = "10001"
        weather_data = {
          current_temp: 75,  # 75°F in Fahrenheit (what the API would return)
          high_temp: 82,     # 82°F in Fahrenheit (what the API would return)
          low_temp: 68,      # 68°F in Fahrenheit (what the API would return)
          conditions: "Sunny",
          extended_forecast: "[]"
        }
        
        weather_service = instance_double(MockWeatherService)
        allow(MockWeatherService).to receive(:new).and_return(weather_service)
        allow(weather_service).to receive(:get_by_address).and_return(weather_data)
        
        # Mock forecast creation
        forecast = build(:forecast)
        allow(Forecast).to receive(:create_from_weather_data).and_return(forecast)
        allow(forecast).to receive(:persisted?).and_return(true)
        
        # Call the service
        result = ForecastRetrievalService.retrieve(address, units: units)
        
        # Verify API was called
        expect(weather_service).to have_received(:get_by_address).with(address, units: units)
        expect(result).to eq(forecast)
        # The service should have converted Fahrenheit to Celsius
        expect(result.current_temp).to eq(24) # 75°F converted to Celsius and rounded
      end
      
      it "returns nil when API returns an error" do
        # Mock weather service to return an error
        weather_service = instance_double(MockWeatherService)
        allow(MockWeatherService).to receive(:new).and_return(weather_service)
        allow(weather_service).to receive(:get_by_address).and_return({ error: "API error" })
        
        # Call the service
        result = ForecastRetrievalService.retrieve(address, units: units)
        
        # Verify nil is returned
        expect(result).to be_nil
      end
    end
    
    context "with rate limiting" do
      it "returns nil when rate limit is exceeded" do
        # Mock rate limiter to reject request
        allow(ApiRateLimiter).to receive(:allow_request?).and_return(false)
        allow(ENV).to receive(:[]).with('OPENWEATHERMAP_API_KEY').and_return('test_key')
        
        # Call the service
        result = ForecastRetrievalService.retrieve(address, units: units)
        
        # Verify nil is returned
        expect(result).to be_nil
      end
    end
    
    context "with missing API key" do
      it "returns nil when API key is missing" do
        # Mock missing API key
        allow(ENV).to receive(:[]).with('OPENWEATHERMAP_API_KEY').and_return(nil)
        
        # Call the service
        result = ForecastRetrievalService.retrieve(address, units: units)
        
        # Verify nil is returned
        expect(result).to be_nil
      end
    end
  end
  
  # Additional tests for private methods if needed, using the #send method
  # to access private methods
end
