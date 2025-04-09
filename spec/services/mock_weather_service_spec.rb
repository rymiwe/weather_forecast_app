require 'rails_helper'

RSpec.describe MockWeatherService do
  let(:service) { described_class.new("test_api_key") }
  
  describe "#initialize" do
    it "accepts an API key (for compatibility)" do
      expect(service).not_to be_nil
    end
  end
  
  describe "#get_by_address" do
    it "returns mock data for any address" do
      result = service.get_by_address("Seattle, WA")
      
      expect(result).to include(
        address: "Seattle, WA",
        zip_code: an_instance_of(String),
        current_temp: a_kind_of(Numeric),
        high_temp: a_kind_of(Numeric),
        low_temp: a_kind_of(Numeric),
        conditions: an_instance_of(String),
        extended_forecast: an_instance_of(String),
        queried_at: an_instance_of(Time)
      )
    end
    
    it "returns consistent data for same address" do
      result1 = service.get_by_address("New York, NY 10001")
      result2 = service.get_by_address("New York, NY 10001")
      
      expect(result1[:current_temp]).to eq(result2[:current_temp])
      expect(result1[:high_temp]).to eq(result2[:high_temp])
      expect(result1[:low_temp]).to eq(result2[:low_temp])
      expect(result1[:conditions]).to eq(result2[:conditions])
    end
    
    it "returns different data for different addresses" do
      result1 = service.get_by_address("New York, NY 10001")
      result2 = service.get_by_address("Los Angeles, CA 90001")
      
      # At least one of these should be different due to random seeding
      differences = [
        result1[:current_temp] != result2[:current_temp],
        result1[:high_temp] != result2[:high_temp],
        result1[:low_temp] != result2[:low_temp],
        result1[:conditions] != result2[:conditions]
      ]
      
      expect(differences.any?).to be true
    end
    
    it "extracts zip code from address" do
      result = service.get_by_address("Test Address 12345")
      expect(result[:zip_code]).to eq("12345")
    end
    
    it "generates valid JSON for extended forecast" do
      result = service.get_by_address("Seattle, WA")
      
      # Should parse without errors
      forecast_data = nil
      expect { forecast_data = JSON.parse(result[:extended_forecast]) }.not_to raise_error
      
      expect(forecast_data).to be_an(Array)
      expect(forecast_data.length).to eq(5), "Should generate a 5-day forecast"
      
      # Check structure of forecast data
      day = forecast_data.first
      expect(day).to include(
        "date", 
        "day_name", 
        "high", 
        "low", 
        "conditions"
      )
    end
  end
end
