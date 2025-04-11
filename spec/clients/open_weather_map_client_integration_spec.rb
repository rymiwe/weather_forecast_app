require 'rails_helper'

RSpec.describe OpenWeatherMapClient, :integration do
  before do
    # Skip the tests if no API key is configured
    skip "Skipping integration tests: No API key configured" unless ENV['OPENWEATHERMAP_API_KEY'].present?
  end
  
  let(:client) { OpenWeatherMapClient.instance }
  
  describe "#get_coordinates" do
    it "fetches coordinates for a valid address" do
      # Use a well-known location for stable testing
      address = "Seattle, WA"
      
      VCR.use_cassette("openweathermap/geocode_seattle") do
        result = client.send(:get_coordinates, address: address)
        
        # Verify the response structure
        expect(result).to be_a(Hash)
        expect(result["lat"]).to be_present
        expect(result["lon"]).to be_present
        # Note: We don't check exact coordinates as the API may return slightly different values
      end
    end
    
    it "returns nil for an invalid address" do
      VCR.use_cassette("openweathermap/geocode_invalid") do
        result = client.send(:get_coordinates, address: "ThisIsNotARealPlaceName12345")
        expect(result).to be_nil
      end
    end
    
    it "handles US zip codes correctly" do
      VCR.use_cassette("openweathermap/geocode_zipcode") do
        result = client.send(:get_coordinates, address: "98101") # Seattle zip code
        expect(result).to be_a(Hash)
        expect(result["lat"]).to be_within(1).of(47.6)
        expect(result["lon"]).to be_within(1).of(-122.3)
      end
    end
  end
  
  describe "#get_weather" do
    it "fetches weather data for a valid address" do
      address = "New York, NY"
      
      VCR.use_cassette("openweathermap/weather_newyork") do
        result = client.get_weather(address: address)
        
        # Check the structure of the response
        expect(result).to be_a(Hash)
        expect(result[:current_weather]).to be_present
        expect(result[:forecast]).to be_present
        
        # Check that the current weather contains the expected fields
        expect(result[:current_weather]["main"]).to be_present
        expect(result[:current_weather]["weather"]).to be_an(Array)
        expect(result[:current_weather]["weather"].first).to have_key("description")
        
        # Check that the forecast contains the expected fields
        expect(result[:forecast]["list"]).to be_an(Array)
        expect(result[:forecast]["list"].first).to have_key("dt")
        expect(result[:forecast]["list"].first).to have_key("main")
      end
    end
    
    it "returns nil for an invalid address" do
      VCR.use_cassette("openweathermap/weather_invalid") do
        result = client.get_weather(address: "ThisIsNotARealPlaceName12345")
        expect(result).to be_nil
      end
    end
  end
  
  describe "caching behavior" do
    it "uses the cache for repeated requests" do
      address = "Boston, MA"
      
      VCR.use_cassette("openweathermap/weather_boston") do
        # The first call should hit the API
        expect(Rails.cache).to receive(:fetch).at_least(:once).and_call_original
        first_result = client.get_weather(address: address)
        expect(first_result).to be_present
        
        # Force a second call which should use the cache
        # We'll only know the cache was used if the API isn't called again
        expect(Net::HTTP).not_to receive(:get_response)
        second_result = client.get_weather(address: address)
        expect(second_result).to eq(first_result)
      end
    end
  end
end
