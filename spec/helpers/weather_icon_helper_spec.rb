# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherIconHelper, type: :helper do
  describe "#weather_icon_name" do
    context "with sunny conditions" do
      it "returns 'sunny' for variations of sunny conditions" do
        expect(helper.weather_icon_name("sunny")).to eq("sunny")
        expect(helper.weather_icon_name("clear sky")).to eq("sunny")
        expect(helper.weather_icon_name("clear")).to eq("sunny")
        expect(helper.weather_icon_name("Sun")).to eq("sunny")
      end
    end
    
    context "with cloudy conditions" do
      it "returns 'cloudy' for variations of cloudy conditions" do
        expect(helper.weather_icon_name("cloudy")).to eq("cloudy")
        expect(helper.weather_icon_name("partly cloudy")).to eq("cloudy")
        expect(helper.weather_icon_name("overcast")).to eq("cloudy")
        expect(helper.weather_icon_name("overcast clouds")).to eq("cloudy")
        expect(helper.weather_icon_name("broken clouds")).to eq("cloudy")
        expect(helper.weather_icon_name("scattered clouds")).to eq("cloudy")
        expect(helper.weather_icon_name("few clouds")).to eq("cloudy")
      end
    end
    
    context "with rainy conditions" do
      it "returns 'rain' for variations of rainy conditions" do
        expect(helper.weather_icon_name("rain")).to eq("rain")
        expect(helper.weather_icon_name("rainy")).to eq("rain")
        expect(helper.weather_icon_name("light rain")).to eq("rain")
        expect(helper.weather_icon_name("moderate rain")).to eq("rain")
        expect(helper.weather_icon_name("heavy rain")).to eq("rain")
        expect(helper.weather_icon_name("showers")).to eq("rain")
        expect(helper.weather_icon_name("scattered showers")).to eq("rain")
        expect(helper.weather_icon_name("drizzle")).to eq("rain")
      end
    end
    
    context "with snowy conditions" do
      it "returns 'snow' for variations of snowy conditions" do
        expect(helper.weather_icon_name("snow")).to eq("snow")
        expect(helper.weather_icon_name("light snow")).to eq("snow")
        expect(helper.weather_icon_name("heavy snow")).to eq("snow")
        expect(helper.weather_icon_name("sleet")).to eq("snow")
        expect(helper.weather_icon_name("winter storm")).to eq("snow")
      end
    end
    
    context "with stormy conditions" do
      it "returns 'thunderstorm' for variations of stormy conditions" do
        expect(helper.weather_icon_name("thunderstorm")).to eq("thunderstorm")
        expect(helper.weather_icon_name("thunder")).to eq("thunderstorm")
        expect(helper.weather_icon_name("lightning")).to eq("thunderstorm")
        expect(helper.weather_icon_name("storm")).to eq("thunderstorm")
      end
    end
    
    context "with foggy conditions" do
      it "returns 'fog' for variations of foggy conditions" do
        expect(helper.weather_icon_name("fog")).to eq("fog")
        expect(helper.weather_icon_name("foggy")).to eq("fog")
        expect(helper.weather_icon_name("mist")).to eq("fog")
        expect(helper.weather_icon_name("haze")).to eq("fog")
      end
    end
    
    context "with nil or unknown conditions" do
      it "returns 'partly_cloudy' for nil or empty conditions" do
        expect(helper.weather_icon_name(nil)).to eq("partly_cloudy")
        expect(helper.weather_icon_name("")).to eq("partly_cloudy")
      end
      
      it "returns 'partly_cloudy' for unrecognized conditions" do
        expect(helper.weather_icon_name("tornado")).to eq("partly_cloudy")
        expect(helper.weather_icon_name("volcanic ash")).to eq("partly_cloudy")
        expect(helper.weather_icon_name("unknown")).to eq("partly_cloudy")
      end
    end
    
    context "with whitespace and case differences" do
      it "handles case and whitespace variations properly" do
        expect(helper.weather_icon_name("  RAIN  ")).to eq("rain")
        expect(helper.weather_icon_name("Clear SKY")).to eq("sunny")
        expect(helper.weather_icon_name("THUNDER storm")).to eq("thunderstorm")
      end
    end
  end
end
