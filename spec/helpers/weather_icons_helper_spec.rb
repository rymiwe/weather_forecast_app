# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherIconsHelper, type: :helper do
  describe "#weather_icon_name" do
    it "returns sunny icon for sunny conditions" do
      expect(helper.weather_icon_name("sunny")).to eq("sunny")
    end

    it "returns cloudy icon for cloudy conditions" do
      expect(helper.weather_icon_name("cloudy")).to eq("cloudy")
    end

    it "returns rainy icon for rainy conditions" do
      expect(helper.weather_icon_name("rain")).to eq("rainy")
    end

    it "returns storm icon for stormy conditions" do
      expect(helper.weather_icon_name("thunderstorm")).to eq("stormy")
    end

    it "returns snow icon for snowy conditions" do
      expect(helper.weather_icon_name("snow")).to eq("snowy")
    end

    it "returns fog icon for foggy conditions" do
      expect(helper.weather_icon_name("fog")).to eq("foggy")
    end

    it "returns windy icon for windy conditions" do
      expect(helper.weather_icon_name("windy")).to eq("windy")
    end

    it "returns partly cloudy icon for unknown conditions" do
      expect(helper.weather_icon_name("unknown")).to eq("partly_cloudy")
    end

    it "handles nil conditions" do
      expect(helper.weather_icon_name(nil)).to eq("partly_cloudy")
    end

    it "matches conditions case-insensitively" do
      expect(helper.weather_icon_name("SUNNY")).to eq("sunny")
    end

    it "matches partial condition words" do
      expect(helper.weather_icon_name("mostly sunny")).to eq("sunny")
    end
  end

  describe "#weather_icon" do
    it "renders the weather icon partial with correct parameters" do
      allow(helper).to receive(:weather_icon_name).with("sunny").and_return("sunny")
      expect(helper).to receive(:render).with(
        partial: 'shared/weather_icon',
        locals: {
          icon_name: "sunny",
          css_classes: "h-8 w-8"
        }
      )
      
      helper.weather_icon("sunny")
    end

    it "passes custom classes to the partial" do
      allow(helper).to receive(:weather_icon_name).with("cloudy").and_return("cloudy")
      expect(helper).to receive(:render).with(
        partial: 'shared/weather_icon',
        locals: {
          icon_name: "cloudy",
          css_classes: "custom-class"
        }
      )
      
      helper.weather_icon("cloudy", "custom-class")
    end
  end
end
