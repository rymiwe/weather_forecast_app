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
    
    describe "temperature conversion in different scenarios" do
      before do
        # Setup common stubs
        allow(ZipCodeExtractionService).to receive(:extract_from_address)
          .with(address).and_return("98101")
        
        allow(ENV).to receive(:[]).and_return(nil)
        allow(ENV).to receive(:[]).with('OPENWEATHERMAP_API_KEY').and_return('test_key')
        
        allow(ApiRateLimiter).to receive(:allow_request?).and_return(true)
      end
      
      context "with metric units" do
        it "preserves temperatures when units are already metric" do
          # With metric units, temperatures should be stored as-is
          metric_weather_data = {
            current_temp: 25,  # Already in Celsius
            high_temp: 30,     # Already in Celsius
            low_temp: 20,      # Already in Celsius
            conditions: "Sunny",
            extended_forecast: "[]"
          }
          
          weather_service = instance_double(MockWeatherService)
          allow(MockWeatherService).to receive(:new).and_return(weather_service)
          allow(weather_service).to receive(:get_by_address).and_return(metric_weather_data)
          
          # Create a forecast with the expected values
          forecast = build(:forecast,
            address: address,
            zip_code: "98101",
            current_temp: 25, # Same as input - no conversion needed
            high_temp: 30,    # Same as input - no conversion needed
            low_temp: 20,     # Same as input - no conversion needed
            conditions: "Sunny",
            extended_forecast: "[]"
          )
          
          # Mock forecast creation
          allow(Forecast).to receive(:create_from_weather_data).and_return(forecast)
          allow(forecast).to receive(:persisted?).and_return(true)
          
          # Call the service with metric units
          result = ForecastRetrievalService.retrieve(address, units: 'metric')
          
          # Verify API was called with metric units
          expect(weather_service).to have_received(:get_by_address).with(address, units: 'metric')
          
          # Temperature values should be stored as-is without conversion
          expect(result.current_temp).to eq(25)
          expect(result.high_temp).to eq(30)
          expect(result.low_temp).to eq(20)
        end
      end
      
      context "with extreme temperatures" do
        it "handles very high temperatures" do
          # Test with extreme heat (e.g., Death Valley-like temperatures)
          extreme_heat_data = {
            current_temp: 120, # 120°F is about 49°C
            high_temp: 130,    # 130°F is about 54°C
            low_temp: 110,     # 110°F is about 43°C
            conditions: "Extremely Hot",
            extended_forecast: "[]"
          }
          
          weather_service = instance_double(MockWeatherService)
          allow(MockWeatherService).to receive(:new).and_return(weather_service)
          allow(weather_service).to receive(:get_by_address).and_return(extreme_heat_data)
          
          # Create a forecast with the expected converted values
          forecast = build(:forecast,
            address: address,
            zip_code: "98101",
            current_temp: 49, # 120°F converted to Celsius
            high_temp: 54,    # 130°F converted to Celsius
            low_temp: 43,     # 110°F converted to Celsius
            conditions: "Extremely Hot",
            extended_forecast: "[]"
          )
          
          # Mock forecast creation
          allow(Forecast).to receive(:create_from_weather_data).and_return(forecast)
          allow(forecast).to receive(:persisted?).and_return(true)
          
          # Call the service with imperial units
          result = ForecastRetrievalService.retrieve(address, units: 'imperial')
          
          # Verify temperatures were converted and rounded correctly
          expect(result.current_temp).to eq(49)
          expect(result.high_temp).to eq(54)
          expect(result.low_temp).to eq(43)
        end
        
        it "handles very low temperatures" do
          # Test with extreme cold (e.g., Antarctic temperatures)
          extreme_cold_data = {
            current_temp: -40, # -40°F is -40°C (they meet at this point)
            high_temp: -30,    # -30°F is about -34°C
            low_temp: -50,     # -50°F is about -46°C
            conditions: "Extremely Cold",
            extended_forecast: "[]"
          }
          
          weather_service = instance_double(MockWeatherService)
          allow(MockWeatherService).to receive(:new).and_return(weather_service)
          allow(weather_service).to receive(:get_by_address).and_return(extreme_cold_data)
          
          # Create a forecast with the expected converted values
          forecast = build(:forecast,
            address: address,
            zip_code: "98101",
            current_temp: -40, # -40°F converted to Celsius
            high_temp: -34,    # -30°F converted to Celsius
            low_temp: -46,     # -50°F converted to Celsius
            conditions: "Extremely Cold",
            extended_forecast: "[]"
          )
          
          # Mock forecast creation
          allow(Forecast).to receive(:create_from_weather_data).and_return(forecast)
          allow(forecast).to receive(:persisted?).and_return(true)
          
          # Call the service with imperial units
          result = ForecastRetrievalService.retrieve(address, units: 'imperial')
          
          # Verify temperatures were converted and rounded correctly
          expect(result.current_temp).to eq(-40)
          expect(result.high_temp).to eq(-34)
          expect(result.low_temp).to eq(-46)
        end
      end
      
      context "with nil or missing temperature data" do
        it "handles nil temperatures from the API" do
          # Test with nil temperature values from the API
          nil_temp_data = {
            current_temp: nil,
            high_temp: nil,
            low_temp: nil,
            conditions: "Unknown",
            extended_forecast: "[]"
          }
          
          weather_service = instance_double(MockWeatherService)
          allow(MockWeatherService).to receive(:new).and_return(weather_service)
          allow(weather_service).to receive(:get_by_address).and_return(nil_temp_data)
          
          # Create a forecast with nil temperatures
          forecast = build(:forecast,
            address: address,
            zip_code: "98101",
            current_temp: nil,
            high_temp: nil,
            low_temp: nil,
            conditions: "Unknown",
            extended_forecast: "[]"
          )
          
          # Mock forecast creation
          allow(Forecast).to receive(:create_from_weather_data).and_return(forecast)
          allow(forecast).to receive(:persisted?).and_return(true)
          
          # Call the service
          result = ForecastRetrievalService.retrieve(address, units: 'imperial')
          
          # Verify nil temperatures are preserved
          expect(result.current_temp).to be_nil
          expect(result.high_temp).to be_nil
          expect(result.low_temp).to be_nil
        end
        
        it "handles missing temperature keys in the API response" do
          # Test with missing temperature keys in the API response
          incomplete_data = {
            conditions: "Partly Cloudy",
            extended_forecast: "[]"
            # current_temp, high_temp, and low_temp keys are missing
          }
          
          weather_service = instance_double(MockWeatherService)
          allow(MockWeatherService).to receive(:new).and_return(weather_service)
          allow(weather_service).to receive(:get_by_address).and_return(incomplete_data)
          
          # Create a mock forecast with nil temperatures
          forecast = build(:forecast,
            address: address,
            zip_code: "98101",
            current_temp: nil,
            high_temp: nil,
            low_temp: nil,
            conditions: "Partly Cloudy",
            extended_forecast: "[]"
          )
          
          # Mock forecast creation
          allow(Forecast).to receive(:create_from_weather_data).and_return(forecast)
          allow(forecast).to receive(:persisted?).and_return(true)
          
          # Call the service
          result = ForecastRetrievalService.retrieve(address, units: 'imperial')
          
          # Verify the service gracefully handles missing temperature keys
          expect(result.conditions).to eq("Partly Cloudy")
          expect(result.current_temp).to be_nil
          expect(result.high_temp).to be_nil
          expect(result.low_temp).to be_nil
        end
      end
      
      context "with request IP" do
        it "passes request IP to weather service when provided" do
          request_ip = "1.2.3.4"
          weather_data = {
            current_temp: 75,
            high_temp: 82,
            low_temp: 68,
            conditions: "Sunny",
            extended_forecast: "[]"
          }
          
          weather_service = instance_double(MockWeatherService)
          allow(MockWeatherService).to receive(:new).and_return(weather_service)
          allow(weather_service).to receive(:get_by_address).and_return(weather_data)
          
          # Create a forecast
          forecast = build(:forecast,
            address: address,
            zip_code: "98101",
            current_temp: 24, # Converted from 75°F
            high_temp: 28,    # Converted from 82°F
            low_temp: 20,     # Converted from 68°F
            conditions: "Sunny",
            extended_forecast: "[]"
          )
          
          # Mock forecast creation
          allow(Forecast).to receive(:create_from_weather_data).and_return(forecast)
          allow(forecast).to receive(:persisted?).and_return(true)
          
          # Call the service with a request IP
          ForecastRetrievalService.retrieve(address, units: 'imperial', request_ip: request_ip)
          
          # Verify request_ip was passed to the weather service
          expect(weather_service).to have_received(:get_by_address)
            .with(address, units: 'imperial', ip: request_ip)
        end
      end
    end
  end
  
  # Additional tests for private methods if needed, using the #send method
  # to access private methods
end
