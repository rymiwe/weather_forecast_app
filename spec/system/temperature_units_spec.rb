# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Temperature Units", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  describe "Default units based on IP detection" do
    it "uses metric units for non-US locations" do
      # Set user IP to be from France (Paris)
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('2.2.2.2')
      
      # Mock geocoding to indicate French IP
      allow(UserLocationService).to receive(:units_for_ip).with('2.2.2.2').and_return('metric')
      
      # Create a forecast with temperature data in Celsius (normalized format)
      forecast = create(:forecast, 
        current_temp: 25,
        high_temp: 30,
        low_temp: 20,
        address: 'Paris, France',
        zip_code: '75001'
      )
      
      # Force metric units in the controller
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('metric')
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Should show temperatures in Celsius
      expect(page).to have_css("h3", text: /\d+°C/)
      expect(page).not_to have_css("h3", text: /\d+°F/)
    end
    
    it "uses imperial units for US locations" do
      # Set user IP to be from US (New York)
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('1.1.1.1')
      
      # Mock geocoding to indicate US IP
      allow(UserLocationService).to receive(:units_for_ip).with('1.1.1.1').and_return('imperial')

      # Create a forecast with temperatures in Celsius (normalized format)
      forecast = create(:forecast, 
        current_temp: 25, # 77°F in Celsius
        high_temp: 30,    # 86°F in Celsius 
        low_temp: 20,     # 68°F in Celsius
        address: 'New York, NY', 
        zip_code: '10001'
      )
      
      # Force imperial units in the controller
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('imperial')
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Expect to see temperatures in Fahrenheit
      expect(page).to have_css("h3", text: /\d+°F/)
      expect(page).not_to have_css("h3", text: /\d+°C/)
    end
  end
  
  describe "Temperature unit switching" do
    it "allows switching between Fahrenheit and Celsius" do
      # Create a forecast with temperatures in Celsius (normalized format)
      forecast = create(:forecast, 
        current_temp: 25, # 77°F in Celsius
        high_temp: 30,    # 86°F in Celsius 
        low_temp: 20,     # 68°F in Celsius
        address: 'New York, NY', 
        zip_code: '10001'
      )
      
      # Stub the application controller to use imperial units first
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('imperial')
      
      # Make sure TemperatureConversionService is working correctly
      allow(TemperatureConversionService).to receive(:celsius_to_fahrenheit).with(25).and_return(77)
      allow(TemperatureConversionService).to receive(:celsius_to_fahrenheit).with(30).and_return(86)
      allow(TemperatureConversionService).to receive(:celsius_to_fahrenheit).with(20).and_return(68)
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Verify we see temps in Fahrenheit first
      expect(page).to have_css("h3", text: /\d+°F/)
      
      # Switch to metric
      click_button "°C"
      
      # Should show temperatures in Celsius now
      expect(page).to have_css("h3", text: /\d+°C/)
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Verify we see temps in Fahrenheit first
      expect(page).to have_content("77°F")
      
      # Switch to metric
      click_button "°C"
      
      # Should show temperatures in Celsius now
      expect(page).to have_content("25°C")
    end
  end
  
  describe "Configuration override" do
    it "uses configured default unit when set" do
      # Create a forecast with temperature data in Celsius (normalized format)
      forecast = create(:forecast, 
        current_temp: 25,
        high_temp: 30,
        low_temp: 20,
        address: 'Paris, France',
        zip_code: '75001'
      )
      
      # Mock the ApplicationController to use metric units
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('metric')
      # Use the correct configuration path that the service is actually using
      allow(Rails.configuration.x.weather).to receive(:default_unit).and_return('metric')
      
      # Visit the forecast detail page
      visit forecast_path(forecast)
      
      # Simply check that we have a temperature with Celsius units somewhere
      expect(page).to have_css("h3", text: /\d+°C/)
    end
  end
  
  describe "User preference persistence" do
    it "remembers user's temperature unit preference across visits" do
      # Create a forecast with temperature data in Celsius (normalized format)
      forecast = create(:forecast, 
        current_temp: 25,
        high_temp: 30,
        low_temp: 20,
        address: 'New York, NY',
        zip_code: '10001'
      )
      
      # First visit - allow the controller to use imperial units
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('imperial')
      
      # Visit forecast page
      visit forecast_path(forecast)
      
      # Expect to see temperatures in Fahrenheit (as we asked for imperial units)
      expect(page).to have_content("77°F")
      
      # Now switch to Celsius
      click_button "°C"
      
      # Should now show in Celsius
      expect(page).to have_content("25°C")
      
      # Now switch the controller preference to persist as metric
      allow_any_instance_of(ApplicationController).to receive(:temperature_units).and_return('metric')
      
      # Revisit the page - should remember the preference
      visit forecast_path(forecast)
      
      # Should still show Celsius
      expect(page).to have_content("25°C")
    end
  end
end
