require 'rails_helper'

RSpec.describe WeatherService do
  let(:api_key) { "test_api_key" }
  let(:service) { described_class.new(api_key) }
  
  describe "#initialize" do
    it "sets the API key" do
      expect(service.instance_variable_get(:@api_key)).to eq(api_key)
    end
  end
  
  describe "#extract_postal_code_from_address" do
    it "returns postal code correctly when present" do
      location_data = {
        'local_names' => {
          'postcode' => '98101'
        }
      }
      
      result = service.send(:extract_postal_code_from_address, location_data)
      expect(result).to eq('98101')
    end
    
    it "returns nil when postal code is missing" do
      result = service.send(:extract_postal_code_from_address, {})
      expect(result).to be_nil
    end
  end
  
  describe "#get_by_address" do
    context "when geocoding fails" do
      it "returns an error hash" do
        allow(service).to receive(:geocode_address).and_return(nil)
        
        result = service.get_by_address("Invalid Address")
        expect(result).to eq({ error: "Could not geocode address" })
      end
    end
    
    context "when geocoding succeeds" do
      it "integrates the full weather retrieval process" do
        # Set up stubs for the entire chain
        allow(service).to receive(:geocode_address).and_return({ lat: 47.6062, lon: -122.3321 })
        allow(service).to receive(:get_zip_code).and_return("98101")
        allow(service).to receive(:fetch_weather_data).and_return({
          current_temp: 52.5,
          high_temp: 58.0,
          low_temp: 48.0,
          conditions: "light rain",
          extended_forecast: "[]",
          queried_at: Time.current
        })
        
        result = service.get_by_address("Seattle, WA")
        
        expect(result).to include(
          address: "Seattle, WA",
          zip_code: "98101",
          current_temp: 52.5
        )
      end
    end
  end
  
  # Tests for private methods
  describe "private methods" do
    describe "#format_extended_forecast" do
      it "formats forecast data into a JSON string" do
        # Sample forecast data from API
        forecast_data = {
          "list" => [
            {
              "dt" => Time.new(2025, 4, 8).to_i,
              "main" => { "temp" => 55.0 },
              "weather" => [{ "main" => "Rain", "description" => "light rain" }]
            },
            {
              "dt" => Time.new(2025, 4, 9).to_i,
              "main" => { "temp" => 58.0 },
              "weather" => [{ "main" => "Clear", "description" => "clear sky" }]
            }
          ]
        }
        
        result = service.send(:format_extended_forecast, forecast_data)
        expect(result).to be_a(String)
        
        parsed_result = JSON.parse(result)
        expect(parsed_result).to be_an(Array)
        
        if parsed_result.any?
          # We skip today's date in the implementation, so we might get the second day
          day = parsed_result.first
          expect(day).to include("date", "day_name", "high", "low", "conditions")
        end
      end
    end
    
    describe "#extract_todays_temps" do
      it "extracts high and low temperatures from forecast data" do
        forecast_data = {
          "list" => [
            {
              "dt" => Time.now.to_i,
              "main" => { "temp" => 55.0 }
            },
            {
              "dt" => Time.now.to_i + 3600,
              "main" => { "temp" => 58.0 }
            }
          ]
        }
        
        allow(Date).to receive(:today).and_return(Time.now.to_date)
        
        result = service.send(:extract_todays_temps, forecast_data)
        expect(result).to include(high: 58.0, low: 55.0)
      end
    end
  end
end
