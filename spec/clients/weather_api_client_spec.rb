# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherApiClient do
  let(:api_key) { 'test_api_key' }
  let(:client) { instance_double(described_class, api_key: api_key, base_url: WeatherApiClient::API_BASE_URL) }
  let(:instance) { described_class.instance }
  let(:address) { 'San Francisco, CA' }
  let(:mock_response) { mock_weather_api_response('San Francisco', region: 'California') }

  before do
    # Stub the singleton instance to return our controlled test double
    allow(described_class).to receive(:instance).and_return(client)
    
    # Stub ENV to return our test API key
    allow(ENV).to receive(:[]).with('WEATHERAPI_KEY').and_return(api_key)
    allow(ENV).to receive(:[]).with(anything).and_call_original
  end

  describe '#get_weather' do
    context 'when using real client' do
      before do
        allow(client).to receive(:use_mock?).and_return(false)
        allow(client).to receive(:real_get_weather).with(address: address).and_return(mock_response)
      end

      it 'calls real_get_weather with the address' do
        expect(client).to receive(:real_get_weather).with(address: address)
        client.get_weather(address: address)
      end

      it 'returns the result from real_get_weather' do
        expect(client.get_weather(address: address)).to eq(mock_response)
      end
    end

    context 'when using mock client' do
      before do
        allow(client).to receive(:use_mock?).and_return(true)
        mock_client = instance_double(MockWeatherApiClient)
        allow(MockWeatherApiClient).to receive(:instance).and_return(mock_client)
        allow(mock_client).to receive(:get_weather).with(address: address).and_return(mock_response)
      end

      it 'delegates to mock client' do
        expect(MockWeatherApiClient.instance).to receive(:get_weather).with(address: address)
        client.get_weather(address: address)
      end
    end

    context 'when API key is missing in production' do
      before do
        allow(ENV).to receive(:[]).with('WEATHERAPI_KEY').and_return(nil)
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(client).to receive(:use_mock?).and_return(false)
      end

      it 'raises an error' do
        expect { client.get_weather(address: address) }.to raise_error(ApiClientBase::ConfigurationError)
      end
    end
  end

  describe 'response processing' do
    let(:instance) { described_class.new }
    
    before do
      # Allow instantiation for testing private methods
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:api_key).and_return(api_key)
    end

    describe '#current_conditions' do
      let(:weather_data) { mock_weather_api_response('Test City') }

      it 'extracts current conditions from weather data' do
        allow(instance).to receive(:current_conditions).and_call_original
        result = instance.send(:current_conditions, weather_data)
        
        expect(result).to be_a(Hash)
        expect(result[:temp_c]).to eq(weather_data['current']['temp_c'])
        expect(result[:temp_f]).to eq(weather_data['current']['temp_f'])
        expect(result[:conditions]).to eq(weather_data['current']['condition']['text'])
        expect(result[:condition_code]).to eq(weather_data['current']['condition']['code'])
      end
    end

    describe '#extract_daily_forecasts' do
      let(:weather_data) { mock_weather_api_response('Test City', days: 3) }

      it 'extracts daily forecasts from weather data' do
        allow(instance).to receive(:extract_daily_forecasts).and_call_original
        result = instance.send(:extract_daily_forecasts, weather_data)
        
        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
        
        # Check first day structure
        first_day = result.first
        expect(first_day[:date]).to eq(weather_data['forecast']['forecastday'][0]['date'])
        expect(first_day[:high_temp_c]).to eq(weather_data['forecast']['forecastday'][0]['day']['maxtemp_c'])
        expect(first_day[:low_temp_c]).to eq(weather_data['forecast']['forecastday'][0]['day']['mintemp_c'])
        expect(first_day[:condition]).to eq(weather_data['forecast']['forecastday'][0]['day']['condition'])
      end
    end
  end
end
