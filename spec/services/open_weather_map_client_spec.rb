require 'rails_helper'

RSpec.describe OpenWeatherMapClient do
  let(:client) { described_class.new }
  let(:address) { "New York, NY" }
  let(:units) { "metric" }
  
  describe "#get_coordinates" do
    it "caches coordinates for the same address" do
      # Setup expectations
      coord_response = { "lat" => 40.7128, "lon" => -74.0060 }
      
      # Expect Rails.cache.fetch to be called with the correct key
      expect(Rails.cache).to receive(:fetch)
        .with("geocode:new york, ny", hash_including(:expires_in))
        .and_return(coord_response)
        
      # Call the method
      result = client.get_coordinates(address: address)
      
      # Verify result
      expect(result).to eq(coord_response)
    end
  end
  
  describe "#get_weather" do
    it "caches weather data for the same address and units" do
      # Mock the coordinates method to avoid external API calls
      coord_response = { "lat" => 40.7128, "lon" => -74.0060 }
      allow(client).to receive(:get_coordinates).and_return(coord_response)
      
      # Create a mock weather response
      weather_response = {
        current_weather: {
          "main" => { "temp" => 20, "temp_min" => 18, "temp_max" => 22 },
          "weather" => [{ "description" => "clear sky" }]
        },
        forecast: {
          "list" => []
        }
      }
      
      # Expect Rails.cache.fetch to be called with the correct key 
      expect(Rails.cache).to receive(:fetch)
        .with("weather:new york, ny:metric", hash_including(:expires_in))
        .and_return(weather_response)
        
      # Call the method
      result = client.get_weather(address: address, units: units)
      
      # Verify result
      expect(result).to eq(weather_response)
    end
  end
  
  describe "caching behavior" do
    it "uses different cache keys for different units" do
      # Mock the coordinates method
      coord_response = { "lat" => 40.7128, "lon" => -74.0060 }
      allow(client).to receive(:get_coordinates).and_return(coord_response)
      
      # Expect different cache keys for different units
      expect(Rails.cache).to receive(:fetch)
        .with("weather:new york, ny:metric", anything)
      expect(Rails.cache).to receive(:fetch)
        .with("weather:new york, ny:imperial", anything)
        
      # Call the method with different units
      client.get_weather(address: address, units: "metric")
      client.get_weather(address: address, units: "imperial")
    end
  end
end
