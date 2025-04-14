# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForecastsController, type: :controller do
  let(:mock_api_response) { mock_weather_api_response('San Francisco', region: 'California') }
  let(:valid_address) { 'San Francisco, CA' }
  let(:valid_forecast) do
    create(:forecast, 
      address: 'San Francisco, CA',
      zip_code: '94105',
      current_temp: 22.5,
      high_temp: 25.0, 
      low_temp: 18.0,
      conditions: 'Partly cloudy',
      extended_forecast: '[{"date":"2025-04-13","day_name":"Sunday","high":25.0,"low":18.0,"conditions":["Partly cloudy"]}]',
      queried_at: Time.current
    )
  end

  before do
    # Stub WeatherApiClient to avoid real API calls
    allow_any_instance_of(WeatherApiClient).to receive(:get_weather).and_return(mock_api_response)
    
    # Stub the Forecast.create_from_api_response method to return our test forecast
    allow(Forecast).to receive(:create_from_api_response).and_return(valid_forecast)
    
    # Stub the normalized address to ensure consistent results
    allow(Forecast).to receive(:normalize_address).and_return('san_francisco_ca')
    
    # Stub AddressPreprocessorService to return a predictable result
    allow(AddressPreprocessorService).to receive(:preprocess).with(valid_address).and_return(valid_address)
  end

  describe 'GET #index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
    
    context 'with address parameter' do
      it 'searches for a forecast' do
        expect(FindOrCreateForecastService).to receive(:call).with(address: valid_address, 
                                                                   request_ip: anything).and_return(valid_forecast)
        get :index, params: { address: valid_address }
      end
      
      it 'assigns the forecast to @forecast' do
        allow(FindOrCreateForecastService).to receive(:call).and_return(valid_forecast)
        get :index, params: { address: valid_address }
        expect(assigns(:forecast)).to eq(valid_forecast)
      end
    end
  end

  describe 'GET #search' do
    context 'with valid address' do
      it 'searches for a forecast and renders index' do
        expect(FindOrCreateForecastService).to receive(:call).with(address: valid_address, 
                                                                   request_ip: anything).and_return(valid_forecast)
        get :search, params: { address: valid_address }
        expect(response).to render_template(:index)
      end
    end
    
    context 'with blank address' do
      it 'redirects to root with alert' do
        get :search, params: { address: '' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
    
    context 'with invalid address' do
      before do
        # Simulate forecast not found
        allow(FindOrCreateForecastService).to receive(:call).and_return(nil)
      end
      
      it 'renders index with error message' do
        get :search, params: { address: 'Invalid Location' }
        expect(response).to render_template(:index)
        expect(flash.now[:alert]).to be_present
      end
    end
    
    context 'when API error occurs' do
      before do
        allow(FindOrCreateForecastService).to receive(:call).and_raise(ApiClientBase::RateLimitExceededError)
      end
      
      it 'handles rate limit errors gracefully' do
        get :search, params: { address: valid_address }
        expect(response).to render_template(:index)
        expect(flash.now[:alert]).to include('Rate limit')
      end
    end
  end
end
