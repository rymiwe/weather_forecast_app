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
    
    it "adapts to the configurable cache duration" do
      # Set a cache duration if needed for test
      original_duration = Rails.configuration.x.weather.cache_duration
      Rails.configuration.x.weather.cache_duration = 30.minutes
      
      # Create a forecast that should be outside cache duration
      create(:forecast, zip_code: "98101", queried_at: 45.minutes.ago)
      expect(Forecast.find_cached("98101")).to be_nil
      
      # Create a forecast that should be within cache duration
      newer_forecast = create(:forecast, zip_code: "60601", queried_at: 5.minutes.ago)
      expect(Forecast.find_cached("60601")).to eq(newer_forecast)
      
      # Restore original configuration
      Rails.configuration.x.weather.cache_duration = original_duration
    end
  end
  
  describe "#cached?" do
    before do
      Rails.configuration.x.weather.cache_duration = 30.minutes
    end
    
    after do
      Rails.configuration.x.weather.cache_duration = 30.minutes
    end
    
    it "returns true when forecast was queried more than 1 minute ago" do
      forecast = build(:forecast, queried_at: 2.minutes.ago)
      expect(forecast.cached?).to be true
    end
    
    it "returns false when forecast is less than 1 minute old" do
      forecast = build(:forecast, queried_at: 30.seconds.ago)
      expect(forecast.cached?).to be false
    end
    
    it "returns false when forecast is older than the cache duration" do
      # Create a forecast with a timestamp old enough to be outside the cache duration
      forecast = build(:forecast, queried_at: 35.minutes.ago)
      expect(forecast.cached?).to be false
    end
  end
  
  describe "#cache_expires_at" do
    before do
      Rails.configuration.x.weather.cache_duration = 30.minutes
    end
    
    after do
      Rails.configuration.x.weather.cache_duration = 30.minutes
    end
    
    it "returns the time when the cache expires" do
      forecast = build(:forecast, queried_at: Time.current)
      expect(forecast.cache_expires_at).to be_within(1.second).of(
        forecast.queried_at + 30.minutes
      )
    end
    
    it "changes with the configurable cache duration" do
      # Change the cache duration for this test
      Rails.configuration.x.weather.cache_duration = 15.minutes
      
      forecast = build(:forecast, queried_at: Time.current)
      expect(forecast.cache_expires_at).to be_within(1.second).of(
        forecast.queried_at + 15.minutes
      )
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
