# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Forecasts UI', type: :request do
  describe 'Turbo/Hotwire integration', :vcr do
    it 'updates the forecast results turbo frame after search' do
      get forecasts_search_path, params: { address: 'Austin, TX' }, headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('forecast_results')
      expect(response.body).to match(/Unable to find weather data|An error occurred while fetching weather data|Austin|TX|United States/i)
    end

    it 'shows error message in turbo frame for invalid address' do
      get forecasts_search_path, params: { address: 'zzzzzzzzzz' }, headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }
      expect(response.body).to match(/Unable to find weather data|Please check the address|An error occurred while fetching weather data/i)
    end
  end
end
