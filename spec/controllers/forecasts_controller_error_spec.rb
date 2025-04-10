require 'rails_helper'

RSpec.describe ForecastsController, type: :controller do
  describe "Error handling in #index" do
    # Test various error scenarios by mocking ForecastRetrievalService
    context "when API errors occur" do
      before do
        allow(ForecastRetrievalService).to receive(:retrieve).and_raise(
          Net::HTTPServerException.new("500 Internal Server Error", nil)
        )
      end
      
      it "handles HTTP errors with proper status codes" do
        get :index, params: { address: "90210" }
        expect(flash.now[:alert]).to include("Unable to connect")
        expect(response).to have_http_status(:service_unavailable)
      end
    end
    
    context "when JSON parsing errors occur" do
      before do
        allow(ForecastRetrievalService).to receive(:retrieve).and_raise(
          JSON::ParserError.new("Invalid JSON")
        )
      end
      
      it "handles JSON errors gracefully" do
        get :index, params: { address: "90210" }
        expect(flash.now[:alert]).to include("Invalid response format")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    
    context "when rate limiting occurs" do
      before do
        allow(ForecastRetrievalService).to receive(:retrieve).and_raise(
          ErrorHandlingService::RateLimitError.new("Rate limit exceeded")
        )
      end
      
      it "displays rate limit messages" do
        get :index, params: { address: "90210" }
        expect(flash.now[:alert]).to include("Rate limit exceeded")
        expect(response).to have_http_status(:too_many_requests)
      end
    end
    
    # Test handling of blank address
    it "handles explicitly empty addresses" do
      get :index, params: { address: "" }
      expect(flash.now[:alert]).to include("Please provide an address")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
