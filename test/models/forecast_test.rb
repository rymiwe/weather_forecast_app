require "test_helper"

class ForecastTest < ActiveSupport::TestCase
  # Setup test data
  def setup
    @valid_forecast = Forecast.new(
      address: "123 Main St, New York, NY 10001",
      zip_code: "10001",
      current_temp: 72.5,
      high_temp: 78.0,
      low_temp: 65.0,
      conditions: "partly cloudy",
      extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":75,"low":62,"conditions":["partly cloudy"]}]',
      queried_at: Time.current
    )
  end

  # Test validations
  test "valid forecast with all attributes" do
    assert @valid_forecast.valid?
  end

  test "forecast requires address" do
    @valid_forecast.address = nil
    assert_not @valid_forecast.valid?
    assert_includes @valid_forecast.errors[:address], "can't be blank"
  end

  test "forecast requires current_temp" do
    @valid_forecast.current_temp = nil
    assert_not @valid_forecast.valid?
    assert_includes @valid_forecast.errors[:current_temp], "can't be blank"
  end

  test "forecast requires queried_at" do
    @valid_forecast.queried_at = nil
    assert_not @valid_forecast.valid?
    assert_includes @valid_forecast.errors[:queried_at], "can't be blank"
  end

  test "forecast requires zip_code" do
    @valid_forecast.zip_code = nil
    assert_not @valid_forecast.valid?
    assert_includes @valid_forecast.errors[:zip_code], "can't be blank"
  end

  test "forecast zip_code must be unique for same queried_at time" do
    # Save the first forecast
    @valid_forecast.save!
    
    # Create a duplicate forecast with same zip_code and queried_at
    duplicate = Forecast.new(
      address: "Different address, same zip",
      zip_code: @valid_forecast.zip_code,
      current_temp: 73.0,
      high_temp: 79.0,
      low_temp: 66.0,
      conditions: "sunny",
      queried_at: @valid_forecast.queried_at
    )
    
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:zip_code], "has already been taken"
    
    # But should be valid if queried_at is different
    duplicate.queried_at = @valid_forecast.queried_at + 1.hour
    assert duplicate.valid?
  end

  # Test scopes
  test "recent scope returns forecasts from last 30 minutes" do
    # Save our valid forecast
    @valid_forecast.save!
    
    # Create an old forecast
    old_forecast = Forecast.create!(
      address: "456 Oak St, Chicago, IL 60606",
      zip_code: "60606",
      current_temp: 65.0,
      high_temp: 70.0,
      low_temp: 60.0,
      conditions: "rainy",
      queried_at: 35.minutes.ago
    )
    
    # Create another recent forecast
    another_recent = Forecast.create!(
      address: "789 Pine St, Boston, MA 02108",
      zip_code: "02108",
      current_temp: 68.0,
      high_temp: 72.0,
      low_temp: 63.0,
      conditions: "cloudy",
      queried_at: 25.minutes.ago
    )
    
    # Test scope
    recent_forecasts = Forecast.recent
    
    assert_includes recent_forecasts, @valid_forecast
    assert_includes recent_forecasts, another_recent
    assert_not_includes recent_forecasts, old_forecast
  end

  # Test class methods
  test "find_cached returns nil for blank zip_code" do
    assert_nil Forecast.find_cached(nil)
    assert_nil Forecast.find_cached("")
  end

  test "find_cached returns recent forecast for zip code" do
    @valid_forecast.save!
    
    # Should find the saved forecast
    found = Forecast.find_cached(@valid_forecast.zip_code)
    assert_equal @valid_forecast.id, found.id
    
    # Create an old forecast with same zip code
    old_forecast = Forecast.create!(
      address: "Same zip, different time",
      zip_code: @valid_forecast.zip_code,
      current_temp: 70.0,
      high_temp: 75.0,
      low_temp: 62.0,
      conditions: "clear",
      queried_at: 40.minutes.ago
    )
    
    # Should still find the most recent one
    found = Forecast.find_cached(@valid_forecast.zip_code)
    assert_equal @valid_forecast.id, found.id
    assert_not_equal old_forecast.id, found.id
  end

  test "create_from_weather_data creates forecast correctly" do
    data = {
      address: "Test Address",
      zip_code: "12345",
      current_temp: 80.0,
      high_temp: 85.0,
      low_temp: 75.0,
      conditions: "sunny",
      extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":82,"low":74,"conditions":["sunny"]}]',
      queried_at: Time.current
    }
    
    forecast = Forecast.create_from_weather_data(data)
    
    assert forecast.persisted?
    assert_equal data[:address], forecast.address
    assert_equal data[:zip_code], forecast.zip_code
    assert_equal data[:current_temp], forecast.current_temp
    assert_equal data[:conditions], forecast.conditions
  end

  # Test instance methods
  test "cached? returns true for forecasts older than 1 minute" do
    @valid_forecast.queried_at = 2.minutes.ago
    assert @valid_forecast.cached?
    
    @valid_forecast.queried_at = 30.seconds.ago
    assert_not @valid_forecast.cached?
  end

  test "extended_forecast_data returns parsed JSON" do
    json_data = '[{"date":"2025-04-08","day_name":"Tuesday","high":75,"low":62,"conditions":["partly cloudy"]}]'
    @valid_forecast.extended_forecast = json_data
    
    parsed_data = @valid_forecast.extended_forecast_data
    
    assert_instance_of Array, parsed_data
    assert_equal 1, parsed_data.size
    assert_equal "Tuesday", parsed_data[0]["day_name"]
    assert_equal 75, parsed_data[0]["high"]
  end

  test "extended_forecast_data returns empty array for invalid JSON" do
    @valid_forecast.extended_forecast = "not valid json"
    assert_empty @valid_forecast.extended_forecast_data
    
    @valid_forecast.extended_forecast = nil
    assert_empty @valid_forecast.extended_forecast_data
  end
end
