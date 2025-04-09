require 'capybara/rspec'
require 'selenium-webdriver'
require 'webdrivers/chromedriver'

# Configure Capybara for system tests
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
  
  # Use this when you want to see the browser in action
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome
  end
end
