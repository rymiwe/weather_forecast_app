# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Temperature Units", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  describe "Default units based on IP detection" do
    it "uses metric units for non-US locations" do
      # Mock the IP detection to return metric units (non-US location)
      allow_any_instance_of(ForecastsController).to receive(:temperature_units).and_return('metric')
      
      # Create a forecast with some temperature data
      forecast = create(:forecast, current_temp: 25, high_temp: 30, low_temp: 20)
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Should show temperatures in Celsius
      expect(page).to have_content("#{forecast.current_temp.round}°C")
      expect(page).to have_content("#{forecast.high_temp.round}°C")
      expect(page).to have_content("#{forecast.low_temp.round}°C")
    end
    
    it "uses imperial units for US locations" do
      # Mock the IP detection to return imperial units (US location)
      allow_any_instance_of(ForecastsController).to receive(:temperature_units).and_return('imperial')
      
      # Create a forecast with some temperature data
      forecast = create(:forecast, current_temp: 77, high_temp: 86, low_temp: 68)
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Should show temperatures in Fahrenheit
      expect(page).to have_content("#{forecast.current_temp.round}°F")
      expect(page).to have_content("#{forecast.high_temp.round}°F")
      expect(page).to have_content("#{forecast.low_temp.round}°F")
    end
  end
  
  describe "Temperature unit switching" do
    it "allows switching between Fahrenheit and Celsius" do
      # Create a forecast
      forecast = create(:forecast, current_temp: 77, high_temp: 86, low_temp: 68)
      
      # Start with imperial units
      allow_any_instance_of(ForecastsController).to receive(:temperature_units).and_return('imperial')
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Initially shows Fahrenheit
      expect(page).to have_content("#{forecast.current_temp.round}°F")
      
      # Click on Celsius link
      click_link "°C"
      
      # Should now show in Celsius (allow some time for page to update)
      expect(page).to have_content("25°C") # 77°F ≈ 25°C
      
      # Click back to Fahrenheit
      click_link "°F"
      
      # Should show Fahrenheit again
      expect(page).to have_content("#{forecast.current_temp.round}°F")
    end
  end
  
  describe "Configuration override" do
    it "uses configured default unit when set" do
      # Set configuration to use metric as default
      allow(Rails.configuration.x.weather).to receive(:default_unit).and_return('metric')
      
      # Don't allow IP detection to override
      allow_any_instance_of(UserLocationService).to receive(:units_for_ip).and_return('imperial')
      
      # Create a forecast
      forecast = create(:forecast, current_temp: 25, high_temp: 30, low_temp: 20)
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Should show temperatures in Celsius (from configuration)
      expect(page).to have_content("#{forecast.current_temp.round}°C")
    end
  end
  
  describe "User preference persistence" do
    it "remembers user's temperature unit preference across visits" do
      # Create a forecast
      forecast = create(:forecast, current_temp: 77, high_temp: 86, low_temp: 68)
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Switch to Celsius
      click_link "°C"
      
      # Go back to search page and then back to detail page
      click_link "Back to Search"
      visit forecast_path(forecast)
      
      # Should remember Celsius preference
      expect(page).to have_content("25°C") # 77°F ≈ 25°C
    end
  end
end
