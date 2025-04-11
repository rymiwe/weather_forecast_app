namespace :screenshots do
  desc "Generate screenshots for different weather conditions"
  task generate: :environment do
    require 'capybara/rails'
    require 'capybara/dsl'
    require 'capybara-screenshot'
    require 'webdrivers'
    
    include Capybara::DSL
    
    Capybara.register_driver :selenium_chrome_headless do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--disable-gpu')
      options.add_argument('--window-size=1280,800')
      
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    
    Capybara.default_driver = :selenium_chrome_headless
    Capybara.javascript_driver = :selenium_chrome_headless
    Capybara.default_max_wait_time = 10
    
    # Weather conditions to capture
    conditions = [
      'clear sky',
      'few clouds',
      'scattered clouds',
      'broken clouds',
      'shower rain',
      'rain',
      'thunderstorm',
      'snow',
      'mist',
      'extreme'
    ]
    
    # Create screenshots directory if it doesn't exist
    screenshots_dir = Rails.root.join('public', 'screenshots')
    FileUtils.mkdir_p(screenshots_dir)
    
    # Mock weather data for each condition
    conditions.each do |condition|
      puts "Generating screenshot for condition: #{condition}"
      
      # Allow the mock client to generate specific weather conditions
      MockOpenWeatherMapClient.instance.mock_condition = condition
      
      # Visit the forecast page with mock data
      visit '/forecasts?address=Screenshot%20City&use_mock=true'
      
      # Wait for page to load
      sleep 3
      
      # Capture screenshot
      filename = "#{condition.gsub(' ', '_')}.png"
      page.save_screenshot(screenshots_dir.join(filename))
      
      puts "Saved screenshot to #{filename}"
    end
    
    puts "Done generating screenshots!"
  end
end
