# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForecastParserService, type: :service do
  describe '.parse' do
    it 'parses valid JSON string' do
      json = '{"forecast":{"forecastday":[]}}'
      result = described_class.parse(json)
      expect(result).to be_a(Hash)
      expect(result['forecast']).to be_a(Hash)
    end

    it 'returns nil for invalid JSON' do
      expect(described_class.parse('not json')).to be_nil
    end

    it 'returns hash if already parsed' do
      hash = { 'forecast' => { 'forecastday' => [] } }
      expect(described_class.parse(hash)).to eq(hash)
    end
  end

  describe '.extract_daily_forecasts' do
    it 'extracts forecast days from parsed data' do
      data = { 'forecast' => { 'forecastday' => [{ 'day' => {} }] } }
      days = described_class.extract_daily_forecasts(data)
      expect(days).to be_an(Array)
      expect(days.first['day']).to be_a(Hash)
    end

    it 'returns empty array if no forecast days' do
      expect(described_class.extract_daily_forecasts({})).to eq([])
    end
  end
end
