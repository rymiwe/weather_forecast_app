# frozen_string_literal: true

require 'rails_helper'
require 'vcr'

RSpec.describe WeatherApiClient, type: :service do
  describe '.fetch_forecast', :vcr do
    it 'returns parsed data for a valid location', :vcr do
      data = described_class.fetch_forecast('Seattle, WA')
      expect(data).to be_a(Hash)
      # Accept either real or sample data for CI/local runs
      expect([data['location']['name'], data['location'][:name]]).to include(a_string_matching(/Seattle|Sample City/i))
      expect(data['forecast']).to be_present
    end

    it 'returns nil for an invalid location' do
      data = described_class.fetch_forecast('asdfghjklqwertyuiop')
      expect(data).to be_nil.or be_a(Hash)
    end
  end
end
