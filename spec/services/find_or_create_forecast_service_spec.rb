# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FindOrCreateForecastService, type: :service do
  before { Forecast.delete_all }
  describe '.call', :vcr do
    it 'returns a forecast for a valid address' do
      forecast = described_class.call(address: 'New York, NY')
      expect(forecast).to be_a(Forecast)
      expect(forecast).to be_persisted.or be_nil
      # Accept normalized address or lat/lon; compare case-insensitively
      expect([forecast&.address&.downcase, forecast&.user_query&.downcase]).to include('new york, ny')
    end

    it 'returns nil for blank address' do
      expect(described_class.call(address: '')).to be_nil
    end

    it 'handles invalid address gracefully', :vcr do
      forecast = described_class.call(address: 'asdfghjklqwertyuiop')
      expect(forecast).to be_nil
    end

    it 'returns nil for a valid ZIP code if geocoding or API fails', :vcr do
      # This test simulates the failure path for a real ZIP code that cannot be geocoded or found by the weather API
      forecast = described_class.call(address: '82001')
      expect(forecast).to be_nil
    end
    context 'when normalizing forecast_data keys' do
      let(:geocoded_double) { double('Geocoded', latitude: 40.0, longitude: -75.0) }
      before do
        allow(Geocoder).to receive(:search).and_return([geocoded_double])
      end

      it 'handles forecast_data with symbol keys' do
        mock_data = {
          current: { temp_c: 20 },
          forecast: { forecastday: [ { day: { maxtemp_c: 25, mintemp_c: 15 } } ] }
        }
        allow_any_instance_of(WeatherApiClient).to receive(:get_weather).and_return(mock_data)
        forecast = described_class.call(address: '12345')
        expect(forecast).to be_a(Forecast)
        expect(forecast.current_temp).to eq(20)
        expect(forecast.high_temp).to eq(25)
        expect(forecast.low_temp).to eq(15)
      end

      it 'handles forecast_data with string keys' do
        mock_data = {
          'current' => { 'temp_c' => 21 },
          'forecast' => { 'forecastday' => [ { 'day' => { 'maxtemp_c' => 26, 'mintemp_c' => 16 } } ] }
        }
        allow_any_instance_of(WeatherApiClient).to receive(:get_weather).and_return(mock_data)
        forecast = described_class.call(address: '54321')
        expect(forecast).to be_a(Forecast)
        expect(forecast.current_temp).to eq(21)
        expect(forecast.high_temp).to eq(26)
        expect(forecast.low_temp).to eq(16)
      end

      it 'handles forecast_data with mixed keys' do
        mock_data = {
          'current' => { temp_c: 22 },
          forecast: { 'forecastday' => [ { day: { 'maxtemp_c' => 27, mintemp_c: 17 } } ] }
        }
        allow_any_instance_of(WeatherApiClient).to receive(:get_weather).and_return(mock_data)
        forecast = described_class.call(address: '67890')
        expect(forecast).to be_a(Forecast)
        expect(forecast.current_temp).to eq(22)
        expect(forecast.high_temp).to eq(27)
        expect(forecast.low_temp).to eq(17)
      end
    end

    it 'returns nil for a valid ZIP code if geocoding or API fails', vcr: false do
      # Disable VCR so Geocoder.search stub is effective; VCR cassette would override the stub.
      mock_geocoder = double(search: [])
      forecast = described_class.call(address: '82001', geocoder: mock_geocoder)
      expect(forecast).to be_nil
    end
  end
end
