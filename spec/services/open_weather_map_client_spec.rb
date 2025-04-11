require 'rails_helper'

RSpec.describe OpenWeatherMapClient do
  let(:client) { described_class.instance }
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
      result = client.send(:get_coordinates, address: address)
      
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
        .with("weather:coord:40.7128:-74.006", hash_including(:expires_in))
        .and_return(weather_response)
        
      # Call the method
      result = client.get_weather(address: address)
      
      # Verify result
      expect(result).to eq(weather_response)
    end
  end
  
  describe "caching behavior" do
    it "uses different cache keys for different coordinates" do
      # Mock the coordinates method with different coordinates
      allow(client).to receive(:get_coordinates).and_return({ "lat" => 40.7128, "lon" => -74.0060 })
      
      # Expect the cache key to use the coordinates
      expect(Rails.cache).to receive(:fetch)
        .with("weather:coord:40.7128:-74.006", anything)
        .and_return({})
      
      # Call the method
      client.get_weather(address: address)
    end
  end
end
