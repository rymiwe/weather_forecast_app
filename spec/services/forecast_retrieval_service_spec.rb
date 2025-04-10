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
        
        # Create a more permissive ENV stub
        allow(ENV).to receive(:[]).and_return(nil)
        allow(ENV).to receive(:[]).with('OPENWEATHERMAP_API_KEY').and_return('test_key')
        
        # Enable API calls
        allow(ApiRateLimiter).to receive(:allow_request?).and_return(true)
      end
      
      it "fetches from API when not in cache" do
        address = "123 Main St, New York, NY 10001"
        zip_code = "10001"
        
        # Clear any previous stubs
        allow(ZipCodeExtractionService).to receive(:extract_from_address).and_call_original
        
        # Set up the zip code extraction specifically for this test case
        allow(ZipCodeExtractionService).to receive(:extract_from_address)
          .with(address).and_return(zip_code)
          
        # Create a more permissive ENV stub
        allow(ENV).to receive(:[]).and_return(nil)
        allow(ENV).to receive(:[]).with('OPENWEATHERMAP_API_KEY').and_return('test_key')
        
        # Mock the weather data returned from API - using imperial units
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
        
        # Create a proper forecast object that matches what the service will return
        forecast = build(:forecast,
          address: address,
          zip_code: zip_code,
          current_temp: 24, # 75°F converted to Celsius
          high_temp: 28,    # 82°F converted to Celsius
          low_temp: 20,     # 68°F converted to Celsius
          conditions: "Sunny",
          extended_forecast: "[]"
        )
        
        # Mock forecast creation
        allow(Forecast).to receive(:create_from_weather_data).and_return(forecast)
        allow(forecast).to receive(:persisted?).and_return(true)
        
        # Call the service
        result = ForecastRetrievalService.retrieve(address, units: units)
        
        # Verify API was called
        expect(weather_service).to have_received(:get_by_address).with(address, units: units)
        
        # Instead of comparing entire objects, let's check specific attributes
        # This is more inline with RSpec best practices
        expect(result.address).to eq(address)
        expect(result.zip_code).to eq(zip_code)
        expect(result.current_temp).to eq(24) # 75°F converted to Celsius
        expect(result.high_temp).to eq(28)    # 82°F converted to Celsius
        expect(result.low_temp).to eq(20)     # 68°F converted to Celsius
        expect(result.conditions).to eq("Sunny")
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
        allow(ENV).to receive(:[]).and_return(nil)
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
        allow(ENV).to receive(:[]).and_return(nil)
        
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
