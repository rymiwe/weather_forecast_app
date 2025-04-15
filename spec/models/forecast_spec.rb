# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forecast, type: :model do
  describe '.create_from_api_response' do
    it 'creates a forecast from valid API response' do
      api_response = Forecast.sample_forecast_data
      forecast = described_class.create_from_api_response('Test Address', api_response)
      expect(forecast).to be_a(Forecast)
      expect(forecast).to be_persisted
      expect(forecast.address).to eq('Test Address')
    end

    it 'returns nil for blank API response' do
      expect(described_class.create_from_api_response('Test Address', nil)).to be_nil
    end
  end

  describe '#forecast_days' do
    it 'returns an array of forecast days' do
      forecast = described_class.sample('Sample Address')
      expect(forecast.forecast_days).to be_an(Array)
      expect(forecast.forecast_days.size).to be > 0
    end
  end

  describe '#display_temperature' do
    it 'formats temperature correctly' do
      forecast = described_class.sample('Sample Address')
      expect(forecast.display_temperature(use_imperial: false)).to match(/\d+°C/)
      expect(forecast.display_temperature(use_imperial: true)).to match(/\d+°F/)
    end
  end
end
