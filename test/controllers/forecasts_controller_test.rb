require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  # Setup test data before each test
  setup do
    @forecast = forecasts(:one)
    
    # Mock the WeatherService for testing
    @mock_weather_data = {
      address: "Test Address, Boston, MA 02108",
      zip_code: "02108",
      current_temp: 68.5,
      high_temp: 72.0,
      low_temp: 63.0,
      conditions: "partly cloudy",
      extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":72,"low":63,"conditions":["partly cloudy"]}]',
      queried_at: Time.current
    }
  end

  # Test the index action with no parameters
  test "should get index with search form" do
    get forecasts_url
    assert_response :success
    
    # Verify the search form is present
    assert_select "form[action=?]", forecasts_path
    assert_select "input[name='address']"
    assert_select "input[type='submit']"
  end
  
  # Test the index action with address parameter but missing API key
  test "should show error when API key is missing" do
    # Ensure API key is not set
    ENV['OPENWEATHERMAP_API_KEY'] = nil
    
    # Submit the form with an address
    get forecasts_url, params: { address: "Boston, MA" }
    assert_response :success
    
    # Verify error message is displayed
    assert_select "div.bg-red-100", /Weather API key is missing/
  end
  
  # Test the show action with a valid forecast
  test "should show forecast details" do
    get forecast_url(@forecast)
    assert_response :success
    
    # Verify forecast details are displayed
    assert_select "h2", @forecast.address
    assert_select "h3", /#{@forecast.current_temp.round}°F/
  end
  
  # Test the show action with an invalid forecast ID
  test "should redirect to index when forecast not found" do
    get forecast_url(id: "nonexistent")
    assert_redirected_to forecasts_path
    
    # Verify flash message
    assert_equal "Forecast not found", flash[:alert]
  end
  
  # Test caching functionality (requires mocking the WeatherService)
  test "should use cached forecast when available" do
    # Setup - Create a recent forecast for a specific zip code
    cached_forecast = Forecast.create!(
      address: "123 Maple St, Boston, MA 02108",
      zip_code: "02108",
      current_temp: 65.0,
      high_temp: 70.0,
      low_temp: 60.0,
      conditions: "sunny",
      extended_forecast: '[]',
      queried_at: 5.minutes.ago
    )
    
    # Test - Request a forecast with the same zip code
    get forecasts_url, params: { address: "02108" }
    assert_response :success
    
    # Verify cached forecast is used
    assert_select "h2", cached_forecast.address
    assert_select "div.bg-blue-100", "Cached Result"
  end
  
  # Test that we properly handle the turbo stream format
  test "should respond to turbo_stream format" do
    # Mock the weather service to avoid API calls
    WeatherService.stub_any_instance(:get_by_address, @mock_weather_data) do
      # Request with turbo_stream format
      get forecasts_url, params: { address: "Boston, MA" }, as: :turbo_stream
      assert_response :success
      assert_equal "text/vnd.turbo-stream.html", @response.media_type
    end
  end
  
  # Test the zip code extraction functionality
  test "should extract zip code from address" do
    address_with_zip = "123 Main St, New York, NY 10001"
    
    # Create a method to call the private controller method
    def extract_zip_code(address)
      @controller = ForecastsController.new
      @controller.send(:extract_zip_code, address)
    end
    
    # Test valid US zip code extraction
    assert_equal "10001", extract_zip_code(address_with_zip)
    
    # Test zip+4 format
    assert_equal "10001", extract_zip_code("123 Main St, New York, NY 10001-1234")
    
    # Test no zip code
    assert_nil extract_zip_code("No zip code here")
  end
end
