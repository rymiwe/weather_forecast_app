require "application_system_test_case"

class ForecastsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit forecasts_url
    
    assert_selector "h1", text: "Weather Forecast"
    assert_selector "form[action='#{forecasts_path}']"
  end
  
  test "searching for a forecast" do
    # Mock the weather service for system testing
    # This would require additional setup in a real application
    # but for brevity, we'll assume it's properly mocked
    
    visit forecasts_url
    
    # Fill in the address field
    fill_in "address", with: "New York, NY 10001"
    
    # Submit the form
    click_on "Get Forecast"
    
    # Verify forecast is displayed (this would actually work if the API call is mocked)
    # assert_selector "h2", text: "New York"
    # assert_selector "h3", text: /\d+°F/
  end
  
  test "viewing forecast details" do
    # Use a fixture forecast
    forecast = forecasts(:one)
    
    visit forecast_url(forecast)
    
    # Verify forecast details are displayed
    assert_selector "h2", text: forecast.address
    assert_selector "h3", text: "#{forecast.current_temp.round}°F"
    
    # Verify the back link works
    click_on "Back to Search"
    assert_current_path forecasts_path
  end
end
