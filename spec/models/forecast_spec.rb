require 'rails_helper'

RSpec.describe Forecast, type: :model do
  describe "validations" do
    it "is valid with all required attributes" do
      forecast = build(:forecast)
      expect(forecast).to be_valid
    end
    
    it "requires an address" do
      forecast = build(:forecast, address: nil)
      expect(forecast).not_to be_valid
      expect(forecast.errors[:address]).to include("can't be blank")
    end
    
    it "requires a zip_code" do
      forecast = build(:forecast, zip_code: nil)
      expect(forecast).not_to be_valid
      expect(forecast.errors[:zip_code]).to include("can't be blank")
    end
    
    it "requires current_temp" do
      forecast = build(:forecast, current_temp: nil)
      expect(forecast).not_to be_valid
      expect(forecast.errors[:current_temp]).to include("can't be blank")
    end
  end
  
  describe ".find_cached" do
    it "returns nil when no matching forecast exists" do
      expect(Forecast.find_cached("00000")).to be_nil
    end
    
    it "returns nil when forecast is too old" do
      create(:forecast, zip_code: "98101", queried_at: 2.hours.ago)
      expect(Forecast.find_cached("98101")).to be_nil
    end
    
    it "returns forecast when recent match exists" do
      forecast = create(:forecast, zip_code: "98101", queried_at: 15.minutes.ago)
      cached = Forecast.find_cached("98101")
      
      expect(cached).to eq(forecast)
    end
    
    context "with multiple forecasts for same zip" do
      it "returns the most recent one" do
        old_forecast = create(:forecast, zip_code: "98101", queried_at: 45.minutes.ago)
        new_forecast = create(:forecast, zip_code: "98101", queried_at: 15.minutes.ago)
        
        cached = Forecast.find_cached("98101")
        expect(cached).to eq(new_forecast)
      end
    end
  end
  
  describe "#cached?" do
    it "returns true when forecast was queried more than 1 minute ago" do
      forecast = build(:forecast, queried_at: 2.minutes.ago)
      expect(forecast.cached?).to be true
    end
    
    it "returns false when forecast is less than 1 minute old" do
      forecast = build(:forecast, queried_at: 30.seconds.ago)
      expect(forecast.cached?).to be false
    end
  end
  
  describe "#extended_forecast_data" do
    it "returns parsed JSON data" do
      json_data = '[{"date":"2025-04-08","day_name":"Tuesday","high":55,"low":46,"conditions":["rain"]}]'
      forecast = build(:forecast, extended_forecast: json_data)
      
      result = forecast.extended_forecast_data
      expect(result).to be_an(Array)
      expect(result.first).to include("date" => "2025-04-08")
    end
    
    it "returns empty array for blank data" do
      forecast = build(:forecast, extended_forecast: nil)
      expect(forecast.extended_forecast_data).to eq([])
    end
    
    it "returns empty array for invalid JSON" do
      forecast = build(:forecast, extended_forecast: "{invalid json}")
      expect(forecast.extended_forecast_data).to eq([])
    end
  end
end
