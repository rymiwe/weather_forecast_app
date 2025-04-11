require 'rails_helper'

RSpec.describe ForecastsController, type: :controller do
  describe "Error handling in #index" do
    # Test various error scenarios by mocking the service
    context "when API errors occur" do
      before do
        allow(FindOrCreateForecastService).to receive(:call).and_raise(
          ApiClientBase::ApiError.new("Unable to connect to weather service")
        )
      end
      
      it "handles HTTP errors with proper status codes" do
        get :index, params: { address: "90210" }
        expect(flash[:alert]).to include("Unable to connect")
        expect(response).to have_http_status(:service_unavailable)
      end
    end
    
    context "when JSON parsing errors occur" do
      before do
        allow(FindOrCreateForecastService).to receive(:call).and_raise(
          JSON::ParserError.new("Invalid JSON")
        )
      end
      
      it "handles JSON errors gracefully" do
        get :index, params: { address: "90210" }
        expect(flash[:alert]).to include("Invalid response format")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    
    context "when rate limiting occurs" do
      before do
        allow(FindOrCreateForecastService).to receive(:call).and_raise(
          ApiClientBase::RateLimitExceededError.new("Rate limit exceeded")
        )
      end
      
      it "displays rate limit messages" do
        get :index, params: { address: "90210" }
        expect(flash[:alert]).to include("Rate limit exceeded")
        expect(response).to have_http_status(:too_many_requests)
      end
    end
    
    # Test handling of blank address
    it "handles explicitly empty addresses" do
      get :index, params: { address: "" }
      expect(flash[:alert]).to include("Please provide an address")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
