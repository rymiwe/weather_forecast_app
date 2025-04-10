require 'rails_helper'

RSpec.describe WeatherCardHelper, type: :helper do
  describe "#forecast_card_background_class" do
    context "condition-based backgrounds" do
      it "returns blue background for rainy conditions" do
        expect(helper.forecast_card_background_class('rain', 20)).to eq('bg-blue-100')
        expect(helper.forecast_card_background_class('light rain', 20)).to eq('bg-blue-100')
        expect(helper.forecast_card_background_class('showers', 20)).to eq('bg-blue-100')
      end
      
      it "returns light blue background for snowy conditions" do
        expect(helper.forecast_card_background_class('snow', 20)).to eq('bg-blue-50')
        expect(helper.forecast_card_background_class('sleet', 20)).to eq('bg-blue-50')
      end
      
      it "returns gray background for cloudy conditions" do
        expect(helper.forecast_card_background_class('cloudy', 20)).to eq('bg-gray-100')
        expect(helper.forecast_card_background_class('clouds', 20)).to eq('bg-gray-100')
      end
      
      it "returns slate background for stormy conditions" do
        expect(helper.forecast_card_background_class('thunderstorm', 20)).to eq('bg-slate-200')
        expect(helper.forecast_card_background_class('storm', 20)).to eq('bg-slate-200')
      end
      
      it "returns yellow background for sunny conditions" do
        expect(helper.forecast_card_background_class('sunny', 20)).to eq('bg-yellow-100')
        expect(helper.forecast_card_background_class('clear', 20)).to eq('bg-yellow-100')
      end
    end
    
    context "temperature-based backgrounds for metric units" do
      it "returns orange background for hot days" do
        expect(helper.forecast_card_background_class('normal', 35, 'metric')).to eq('bg-orange-50')
      end
      
      it "returns indigo background for cold days" do
        expect(helper.forecast_card_background_class('normal', 5, 'metric')).to eq('bg-indigo-50')
      end
      
      it "returns default background for mild temperatures" do
        expect(helper.forecast_card_background_class('normal', 20, 'metric')).to eq('bg-gray-50')
      end
    end
    
    context "temperature-based backgrounds for imperial units" do
      it "returns orange background for hot days" do
        expect(helper.forecast_card_background_class('normal', 90, 'imperial')).to eq('bg-orange-50')
      end
      
      it "returns indigo background for cold days" do
        expect(helper.forecast_card_background_class('normal', 40, 'imperial')).to eq('bg-indigo-50')
      end
      
      it "returns default background for mild temperatures" do
        expect(helper.forecast_card_background_class('normal', 70, 'imperial')).to eq('bg-gray-50')
      end
    end
    
    context "priority of condition vs temperature" do
      it "prioritizes condition over temperature" do
        # Even though 35°C would normally trigger 'bg-orange-50' for hot temperatures,
        # the 'rain' condition takes precedence
        expect(helper.forecast_card_background_class('rain', 35, 'metric')).to eq('bg-blue-100')
      end
    end
  end
end
