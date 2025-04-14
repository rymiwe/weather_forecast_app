# frozen_string_literal: true

require 'rails_helper'
require 'weather_api_test_helpers'

RSpec.describe MockWeatherApiClient do
  let(:client) { described_class.instance }
  let(:address) { 'San Francisco, CA' }

  describe '#get_weather' do
    it 'returns a hash with the expected WeatherAPI.com structure' do
      result = client.get_weather(address: address)
      
      # Verify the response structure matches what our app expects
      expect(result).to be_a(Hash)
      expect(result).to have_key('location')
      expect(result).to have_key('current')
      expect(result).to have_key('forecast')
      
      # Check location data
      expect(result['location']).to have_key('name')
      expect(result['location']).to have_key('region')
      expect(result['location']).to have_key('country')
      expect(result['location']).to have_key('lat')
      expect(result['location']).to have_key('lon')
      expect(result['location']).to have_key('tz_id')
      
      # Check current weather data
      expect(result['current']).to have_key('temp_c')
      expect(result['current']).to have_key('temp_f')
      expect(result['current']).to have_key('condition')
      expect(result['current']['condition']).to have_key('text')
      expect(result['current']['condition']).to have_key('code')
      
      # Check forecast data
      expect(result['forecast']).to have_key('forecastday')
      expect(result['forecast']['forecastday']).to be_an(Array)
      expect(result['forecast']['forecastday'].length).to be.positive?
      
      # Check first forecast day
      first_day = result['forecast']['forecastday'].first
      expect(first_day).to have_key('date')
      expect(first_day).to have_key('day')
      expect(first_day['day']).to have_key('maxtemp_c')
      expect(first_day['day']).to have_key('maxtemp_f')
      expect(first_day['day']).to have_key('mintemp_c')
      expect(first_day['day']).to have_key('mintemp_f')
      expect(first_day['day']).to have_key('condition')
    end
    
    it 'uses the address in the location name' do
      result = client.get_weather(address: address)
      expect(result['location']['name']).to include('San Francisco')
    end
    
    it 'generates different temperatures for different days' do
      result = client.get_weather(address: address)
      return if result['forecast']['forecastday'].length <= 1
      
      temps = result['forecast']['forecastday'].map { |day| day['day']['maxtemp_c'] }
      # Either temps should differ or we should get an array of length 1 (which is fine)
      expect(temps.uniq.count).to be > 1 unless temps.length <= 1
    end
  end
  
  describe 'singleton pattern' do
    it 'returns the same instance when called multiple times' do
      instance1 = described_class.instance
      instance2 = described_class.instance
      expect(instance1).to be(instance2)
    end
  end
end
