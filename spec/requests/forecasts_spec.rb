# frozen_string_literal: true

require 'rails_helper'
require 'vcr'

RSpec.describe 'Forecasts', type: :request do
  describe 'GET /' do
    it 'renders the home page' do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Weather Forecast')
    end
  end

  describe 'GET /forecasts/search', :vcr do
    let(:address) { 'San Francisco, CA' }

    it 'returns a weather forecast for a valid address' do
      get forecasts_search_path, params: { address: address }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('San Francisco')
      expect(response.body).to match(/\d{1,3}°[CF]/)
    end

    it 'handles blank address gracefully' do
      get forecasts_search_path, params: { address: '' }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('Please provide an address')
    end

    it 'handles invalid address gracefully', :vcr do
      get forecasts_search_path, params: { address: 'asdfghjklqwertyuiop' }
      expect(response.body).to match(/Unable to find weather data|Please check the address/i)
    end
  end
end
