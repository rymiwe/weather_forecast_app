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
    
    context 'when caching is enabled' do
      let(:cache_key) { "weather:#{address.parameterize}" }
      
      before do
        allow(client).to receive(:use_mock?).and_return(false)
        allow(client).to receive(:fetch_or_cache_weather).with(address).and_call_original
        allow(Rails.cache).to receive(:fetch).with(cache_key, any_args).and_return(mock_response)
      end
      
      it 'uses Rails.cache.fetch with the correct key' do
        expect(Rails.cache).to receive(:fetch).with(cache_key, any_args)
        allow(client).to receive(:real_get_weather).and_return(mock_response)
        client.get_weather(address: address)
      end
      
      it 'logs cache operations' do
        expect(Rails.logger).to receive(:info).with(/Getting weather for address/)
        allow(client).to receive(:real_get_weather).and_return(mock_response)
        client.get_weather(address: address)
      end
    end
  end
  
  describe '#make_api_request' do
    let(:instance) { described_class.new }
    let(:faraday_connection) { instance_double(Faraday::Connection) }
    let(:faraday_response) { instance_double(Faraday::Response, status: 200, body: mock_response.to_json) }
    let(:api_url) { "#{WeatherApiClient::API_BASE_URL}/forecast.json" }
    
    before do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:api_key).and_return(api_key)
      allow(Faraday).to receive(:new).and_return(faraday_connection)
      allow(faraday_connection).to receive(:get).and_return(faraday_response)
    end
    
    it 'makes a GET request to the correct API endpoint' do
      expect(Faraday).to receive(:new).with(url: WeatherApiClient::API_BASE_URL)
      expect(faraday_connection).to receive(:get).with(
        'forecast.json',
        hash_including(key: api_key, q: address, days: 7)
      )
      
      instance.send(:make_api_request, endpoint: 'forecast.json', params: { q: address, days: 7 })
    end
    
    context 'when API request fails' do
      let(:error_response) { instance_double(Faraday::Response, status: 400, body: { error: { message: "Invalid request" } }.to_json) }
      
      before do
        allow(faraday_connection).to receive(:get).and_return(error_response)
      end
      
      it 'returns the error data with status' do
        expect(Rails.logger).to receive(:error).with(/API request failed/)
        result = instance.send(:make_api_request, endpoint: 'forecast.json', params: { q: address })
        expect(result).to include(:error)
        expect(result[:status]).to eq(400)
      end
    end
    
    context 'when network error occurs' do
      before do
        allow(faraday_connection).to receive(:get).and_raise(Faraday::ConnectionFailed.new("Connection refused"))
      end
      
      it 'returns an error response' do
        expect(Rails.logger).to receive(:error).with(/Network error/)
        result = instance.send(:make_api_request, endpoint: 'forecast.json', params: { q: address })
        expect(result).to include(:error)
        expect(result[:error]).to include("Connection failed")
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
      
      it 'handles missing current data gracefully' do
        incomplete_data = {}
        allow(instance).to receive(:current_conditions).and_call_original
        
        result = instance.send(:current_conditions, incomplete_data)
        expect(result).to be_a(Hash)
        expect(result[:conditions]).to be_nil
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
      
      it 'returns an empty array when forecast data is missing' do
        incomplete_data = {}
        result = instance.send(:extract_daily_forecasts, incomplete_data)
        expect(result).to eq([])
      end
    end
    
    describe '#format_weather_data' do
      let(:weather_data) { mock_weather_api_response('Test City', region: 'Test Region', days: 3) }
      
      it 'combines location, current, and forecast data' do
        result = instance.send(:format_weather_data, weather_data)
        
        expect(result).to be_a(Hash)
        expect(result[:location]).to include(
          name: 'Test City',
          region: 'Test Region'
        )
        expect(result[:current]).to include(:temp_c, :temp_f, :conditions)
        expect(result[:forecasts]).to be_an(Array)
        expect(result[:forecasts].length).to eq(3)
      end
    end
  end
end
