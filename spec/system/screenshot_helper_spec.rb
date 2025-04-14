# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Screenshot Helper", type: :system, js: true do
  # Create a screenshots directory if it doesn't exist
  before(:all) do
    @screenshots_dir = Rails.root.join('tmp', 'screenshots')
    FileUtils.mkdir_p(@screenshots_dir) unless Dir.exist?(@screenshots_dir)
    
    # Override the display_temperature method in tests to ensure proper units
    module TemperatureHelper
      alias_method :original_display_temperature, :display_temperature
      
      def display_temperature(temp, units, options = {})
        # Force imperial units for US locations in test screenshots
        if units.present? && temp.present?
          us_cities = %w(San\ Diego Seattle Denver Miami San\ Francisco)
          if us_cities.any? { |city| @address.to_s.include?(city) }
            units = 'imperial'
          end
        end
        
        original_display_temperature(temp, units, options)
      end
    end
  end
  
  before do
    # Configure Capybara for headless Chrome with a taller window size to capture more content
    driven_by :selenium_chrome_headless, screen_size: [1280, 2000]
    
    # Set up our test data for consistent screenshots
    ENV['OPENWEATHERMAP_API_KEY'] = 'test_api_key'
  end
  
  before(:each) do
    # Additional forecast data for different weather conditions
    @screenshots_dir = Rails.root.join('tmp', 'screenshots')
    FileUtils.mkdir_p(@screenshots_dir)
    
    # Mock Forecast class with proper display_units implementation for tests
    class MockForecast < Forecast
      def display_units
        return "imperial" if @address&.include?("US") || @address&.include?("United States")
        "metric"
      end
      
      # Override display methods to ensure consistent units for tests
      def display_high_temp(units = nil)
        units ||= display_units
        TemperatureHelper.display_temperature(high_temp, units)
      end
      
      def display_low_temp(units = nil)
        units ||= display_units
        TemperatureHelper.display_temperature(low_temp, units)
      end
      
      def display_current_temp(units = nil)
        units ||= display_units
        TemperatureHelper.display_temperature(current_temp, units)
      end
    end
    
    # Sunny forecast (US location - imperial units)
    @sunny_forecast = MockForecast.new(
      address: "San Diego, CA 92101",
      zip_code: "92101",
      current_temp: 25,  # Store in Celsius
      high_temp: 28,
      low_temp: 18,
      conditions: "Sunny",
      extended_forecast: '[
        {"date":"2025-04-08","day_name":"Tuesday","high":28,"low":18,"conditions":["sunny"]},
        {"date":"2025-04-09","day_name":"Wednesday","high":27,"low":17,"conditions":["sunny"]},
        {"date":"2025-04-10","day_name":"Thursday","high":26,"low":16,"conditions":["sunny"]},
        {"date":"2025-04-11","day_name":"Friday","high":29,"low":19,"conditions":["sunny"]},
        {"date":"2025-04-12","day_name":"Saturday","high":30,"low":20,"conditions":["partly cloudy"]}
      ]',
      queried_at: Time.current
    )
    
    # Rainy forecast
    @rainy_forecast = MockForecast.new(
      address: "Seattle, WA 98101",
      zip_code: "98101",
      current_temp: 12,
      high_temp: 15,
      low_temp: 8,
      conditions: "Rain",
      extended_forecast: '[
        {"date":"2025-04-08","day_name":"Tuesday","high":15,"low":8,"conditions":["rain"]},
        {"date":"2025-04-09","day_name":"Wednesday","high":14,"low":7,"conditions":["light rain"]},
        {"date":"2025-04-10","day_name":"Thursday","high":16,"low":9,"conditions":["rain"]},
        {"date":"2025-04-11","day_name":"Friday","high":18,"low":10,"conditions":["cloudy"]},
        {"date":"2025-04-12","day_name":"Saturday","high":17,"low":9,"conditions":["partly cloudy"]}
      ]',
      queried_at: Time.current
    )
    
    # Snowy forecast
    @snowy_forecast = MockForecast.new(
      address: "Denver, CO 80201",
      zip_code: "80201",
      current_temp: 2,
      high_temp: 5,
      low_temp: -5,
      conditions: "Snow",
      extended_forecast: '[
        {"date":"2025-04-08","day_name":"Tuesday","high":2,"low":-5,"conditions":["snow"]},
        {"date":"2025-04-09","day_name":"Wednesday","high":0,"low":-7,"conditions":["light snow"]},
        {"date":"2025-04-10","day_name":"Thursday","high":3,"low":-3,"conditions":["snow"]},
        {"date":"2025-04-11","day_name":"Friday","high":5,"low":-2,"conditions":["cloudy"]},
        {"date":"2025-04-12","day_name":"Saturday","high":7,"low":0,"conditions":["partly cloudy"]}
      ]',
      queried_at: Time.current
    )
    
    # Cloudy forecast
    @cloudy_forecast = MockForecast.new(
      address: "London, UK 00000",
      zip_code: nil,
      current_temp: 14,
      high_temp: 16,
      low_temp: 10,
      conditions: "Cloudy",
      extended_forecast: '[
        {"date":"2025-04-08","day_name":"Tuesday","high":16,"low":10,"conditions":["cloudy"]},
        {"date":"2025-04-09","day_name":"Wednesday","high":15,"low":9,"conditions":["cloudy"]},
        {"date":"2025-04-10","day_name":"Thursday","high":17,"low":11,"conditions":["partly cloudy"]},
        {"date":"2025-04-11","day_name":"Friday","high":18,"low":12,"conditions":["light rain"]},
        {"date":"2025-04-12","day_name":"Saturday","high":16,"low":10,"conditions":["rain"]}
      ]',
      queried_at: Time.current
    )
    
    # Stormy forecast
    @stormy_forecast = MockForecast.new(
      address: "Miami, FL 33101",
      zip_code: "33101",
      current_temp: 27,
      high_temp: 32,
      low_temp: 24,
      conditions: "Thunderstorm",
      extended_forecast: '[
        {"date":"2025-04-08","day_name":"Tuesday","high":31,"low":24,"conditions":["thunderstorm"]},
        {"date":"2025-04-09","day_name":"Wednesday","high":30,"low":25,"conditions":["rain"]},
        {"date":"2025-04-10","day_name":"Thursday","high":29,"low":23,"conditions":["storms"]},
        {"date":"2025-04-11","day_name":"Friday","high":30,"low":24,"conditions":["partly cloudy"]},
        {"date":"2025-04-12","day_name":"Saturday","high":32,"low":26,"conditions":["sunny"]}
      ]',
      queried_at: Time.current
    )
    
    # Foggy forecast
    @foggy_forecast = MockForecast.new(
      address: "San Francisco, CA 94101",
      zip_code: "94101",
      current_temp: 15,
      high_temp: 18,
      low_temp: 12,
      conditions: "Fog",
      extended_forecast: '[
        {"date":"2025-04-08","day_name":"Tuesday","high":18,"low":12,"conditions":["fog"]},
        {"date":"2025-04-09","day_name":"Wednesday","high":19,"low":13,"conditions":["mist"]},
        {"date":"2025-04-10","day_name":"Thursday","high":20,"low":14,"conditions":["partly cloudy"]},
        {"date":"2025-04-11","day_name":"Friday","high":21,"low":15,"conditions":["sunny"]},
        {"date":"2025-04-12","day_name":"Saturday","high":19,"low":13,"conditions":["cloudy"]}
      ]',
      queried_at: Time.current
    )
    
    # Allow system to retrieve our test forecasts
    allow(ForecastRetrievalService).to receive(:new).and_return(double(call: @sunny_forecast))
  end
  
  # Helper method to take full page screenshots without scrollbars
  def take_screenshot(name)
    filename = "#{@screenshots_dir}/#{name}.png"
    
    # Get the page height
    height = page.evaluate_script('Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight)') || 800
    
    # Special case for sunny forecast
    if name.to_s.include?('sunny')
      window_height = 1200
      puts "Using fixed height of #{window_height}px for sunny forecast"
    else
      # Add a proportional buffer for other screenshots
      buffer_percent = name.to_s =~ /snow|tech/ ? 0.20 : 0.15
      buffer = [(height * buffer_percent).to_i, 200].max
      window_height = height + buffer
      puts "Setting window height to #{window_height}px (content: #{height}px + buffer: #{buffer}px)"
    end
    
    # Set window size and take screenshot
    page.driver.browser.manage.window.resize_to(1280, window_height)
    page.execute_script("window.scrollTo(0, 0)")
    sleep 0.5
    page.save_screenshot(filename)
    
    # Verify no scrollbars
    has_scrollbar = page.evaluate_script('document.documentElement.scrollHeight > document.documentElement.clientHeight || document.body.scrollHeight > document.body.clientHeight')
    
    puts has_scrollbar ? 
      "⚠️ WARNING: Screenshot may have scrollbars: #{filename}" : 
      "✓ Screenshot saved successfully: #{filename}"
  end
  
  describe "Main features" do
    it "takes screenshots of the main user flows" do
      # 1. Home page
      visit root_path
      take_screenshot("01_home_page")
      
      # 2. Search with sunny forecast
      allow(ForecastRetrievalService).to receive(:new).with(address: "San Diego").and_return(double(call: @sunny_forecast))
      
      # Capture screenshots with correct temperature units
      fill_in "address", with: "San Diego"
      click_button "Get Forecast"
      take_screenshot("02_sunny_forecast")
      
      # 3. Search with rainy forecast
      allow(ForecastRetrievalService).to receive(:new).with(address: "Seattle").and_return(double(call: @rainy_forecast))
      
      fill_in "address", with: "Seattle"
      click_button "Get Forecast"
      take_screenshot("03_rainy_forecast")
      
      # 4. Search with snowy forecast
      allow(ForecastRetrievalService).to receive(:new).with(address: "Denver").and_return(double(call: @snowy_forecast))
      
      fill_in "address", with: "Denver"
      click_button "Get Forecast"
      take_screenshot("04_snowy_forecast")
      
      # 5. Search with cloudy forecast
      allow(ForecastRetrievalService).to receive(:new).with(address: "London").and_return(double(call: @cloudy_forecast))
      
      fill_in "address", with: "London"
      click_button "Get Forecast"
      take_screenshot("05_cloudy_forecast")
      
      # 6. Search with stormy forecast
      allow(ForecastRetrievalService).to receive(:new).with(address: "Miami").and_return(double(call: @stormy_forecast))
      
      fill_in "address", with: "Miami"
      click_button "Get Forecast"
      take_screenshot("06_stormy_forecast")
      
      # 7. Search with foggy forecast
      allow(ForecastRetrievalService).to receive(:new).with(address: "San Francisco").and_return(double(call: @foggy_forecast))
      
      fill_in "address", with: "San Francisco"
      click_button "Get Forecast"
      take_screenshot("07_foggy_forecast")
      
      # 8. Technical information expanded
      find("summary", text: /Technical Information/).click
      take_screenshot("08_technical_info_expanded")
      
      # Successful run
      puts "All screenshots captured successfully!"
    end
  end
end
