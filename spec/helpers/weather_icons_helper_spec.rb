# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherIconsHelper, type: :helper do
  describe "#weather_icon" do
    it "returns sunny icon for sunny conditions" do
      expect(helper.weather_icon("sunny")).to include("viewBox")
      expect(helper.weather_icon("sunny")).to include("circle")
      expect(helper.weather_icon("sunny")).to include("#FFD700") # Yellow sun color
    end
    
    it "returns cloudy icon for cloudy conditions" do
      expect(helper.weather_icon("cloudy")).to include("viewBox")
      expect(helper.weather_icon("cloudy")).to include("path")
      expect(helper.weather_icon("cloudy")).to include("#D1D5DB") # Cloud color
    end
    
    it "returns rainy icon for rainy conditions" do
      expect(helper.weather_icon("rain")).to include("viewBox")
      expect(helper.weather_icon("rain")).to include("line")
      expect(helper.weather_icon("rain")).to include("#3B82F6") # Rain color
    end
    
    it "returns storm icon for stormy conditions" do
      expect(helper.weather_icon("thunderstorm")).to include("viewBox")
      expect(helper.weather_icon("thunderstorm")).to include("polyline")
      expect(helper.weather_icon("thunderstorm")).to include("#FBBF24") # Lightning color
    end
    
    it "returns snow icon for snowy conditions" do
      expect(helper.weather_icon("snow")).to include("viewBox")
      expect(helper.weather_icon("snow")).to include("circle")
      expect(helper.weather_icon("snow")).to include("#E5E7EB") # Snow color
    end
    
    it "returns fog icon for foggy conditions" do
      expect(helper.weather_icon("fog")).to include("viewBox")
      expect(helper.weather_icon("fog")).to include("line")
      expect(helper.weather_icon("fog")).to include("#9CA3AF") # Fog color
    end
    
    it "returns windy icon for windy conditions" do
      expect(helper.weather_icon("windy")).to include("viewBox")
      expect(helper.weather_icon("windy")).to include("path")
      expect(helper.weather_icon("windy")).to include("#6B7280") # Wind color
    end
    
    it "returns partly cloudy icon for unknown conditions" do
      expect(helper.weather_icon("unknown")).to include("viewBox")
      expect(helper.weather_icon("unknown")).to include("path")
      expect(helper.weather_icon("unknown")).to include("#D1D5DB") # Cloud color
      expect(helper.weather_icon("unknown")).to include("#FFD700") # Sun color
    end
    
    it "handles nil conditions" do
      expect(helper.weather_icon(nil)).to include("viewBox")
      expect(helper.weather_icon(nil)).to include("path")
    end
    
    it "applies custom classes" do
      custom_class = "my-custom-class h-10 w-10"
      expect(helper.weather_icon("sunny", custom_class)).to include(custom_class)
      expect(helper.weather_icon("sunny", custom_class)).not_to include("h-8 w-8")
    end
    
    it "matches conditions case-insensitively" do
      expect(helper.weather_icon("SUNNY")).to include("#FFD700")
      expect(helper.weather_icon("Cloudy")).to include("#D1D5DB")
    end
    
    it "matches partial condition words" do
      expect(helper.weather_icon("light rainfall")).to include("#3B82F6") # Rain icon
      expect(helper.weather_icon("partly cloudy")).to include("#D1D5DB") # Cloud color
    end
  end
end
