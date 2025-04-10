require 'capybara/rspec'
require 'selenium-webdriver'
require 'webdrivers/chromedriver'

# Configure Capybara for system tests
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
  
  # Default to headless Chrome for JavaScript tests for CI environment and better performance
  # Use `SHOW_BROWSER=true bundle exec rspec` to see the browser during test execution
  config.before(:each, type: :system, js: true) do
    if ENV['SHOW_BROWSER'] == 'true'
      # For debugging with visible browser
      driven_by :selenium_chrome
    else
      # For regular testing and CI environments
      driven_by :selenium_chrome_headless
    end
  end
end
