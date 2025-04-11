# frozen_string_literal: true

class ForecastsController < ApplicationController
  before_action :set_forecast, only: [:show]
  
  # Display forecast search form and results
  def index
    # Home page with search form
    @recent_forecasts = Forecast.recent.limit(5)
    
    # Handle search if address is provided
    if params[:address].present?
      begin
        @address = params[:address]
        @forecast = FindOrCreateForecastService.call(address: @address, request_ip: request.remote_ip)
        
        if @forecast.nil?
          flash.now[:alert] = "We couldn't find weather data for '#{@address}'. Please check the address or zip code and try again."
          @search_error = true
          @recent_forecasts = Forecast.recent.limit(10)
          return
        end
        
        @units = @forecast.display_units
        @search_query = @address
        
        # Always render the index template with results instead of redirecting
        render :index
      rescue ApiClientBase::RateLimitExceededError => e
        # Handle rate limit errors
        flash.now[:alert] = "Rate limit exceeded. Please try again later."
        @search_error = true
      rescue ApiClientBase::AuthenticationError => e
        # Handle authentication errors
        flash.now[:alert] = "API authentication error. Please check your API key."
        @search_error = true
      rescue StandardError => e
        # General error handling
        Rails.logger.error("Error in forecast search: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        flash.now[:alert] = "An error occurred while fetching weather data. Please try again later."
        @search_error = true
      end
    end
  end
  
  # Display forecast search results
  def search
    Rails.logger.debug "ForecastsController#search: Searching for address: #{params[:address]}"
    address = params[:address]
    
    if address.blank?
      Rails.logger.warn "ForecastsController#search: Blank address provided"
      flash[:alert] = "Please enter a location to search for."
      redirect_to root_path
      return
    end
    
    # Clear any existing flash messages to prevent duplicates
    flash.clear
    
    # Use the service to find or create the forecast
    @forecast = FindOrCreateForecastService.call(address: address, request_ip: request.remote_ip)
    
    if @forecast.nil?
      Rails.logger.error "ForecastsController#search: Failed to create forecast"
      # Clear the current forecast
      @forecast = nil
      @search_query = address
      @search_error = true
      flash.now[:alert] = "We couldn't find weather data for '#{address}'. Please check the address or zip code and try again."
      @recent_forecasts = Forecast.recent.limit(5)
      render :index
    else
      Rails.logger.info "ForecastsController#search: Successfully found/created forecast with ID: #{@forecast.id}"
      
      # Set display units (always display in local units based on location)
      @units = @forecast.display_units
      
      # Keep the search form by setting the search query
      @search_query = address
      
      # Show results on the index page with the search form
      @recent_forecasts = Forecast.recent.limit(5)
      render :index
    end
  end
  
  # Test action to create a forecast with mock data
  def test_forecast
    address = params[:address] || "Portland, OR"
    
    # Create a new forecast using our mock method
    Rails.logger.info "TEST: Creating mock forecast for #{address}"
    forecast = Forecast.mock_forecast(address)
    
    if forecast
      Rails.logger.info "TEST: Successfully created forecast for #{address}, ID: #{forecast.id}"
      redirect_to forecast_path(forecast)
    else
      Rails.logger.error "TEST: Failed to create forecast"
      flash[:alert] = "Failed to create test forecast"
      redirect_to root_path
    end
  end
  
  # Simple demo action that always works
  def demo
    Rails.logger.info "ForecastsController#demo: Creating guaranteed demo forecast"
    
    # Create a demo forecast with mock data in the most direct way possible
    forecast = Forecast.new(
      address: "Portland, OR 97219",
      zip_code: "97219",
      current_temp: 24,  # in Celsius 
      high_temp: 28,
      low_temp: 20,
      conditions: "clear sky",
      extended_forecast: {
        current_weather: {
          "main" => {
            "temp" => 24,
            "temp_min" => 20,
            "temp_max" => 28
          },
          "weather" => [
            { "description" => "clear sky" }
          ]
        },
        forecast: {
          "list" => (1..5).map do |i|
            {
              "dt" => Time.current.advance(days: i).to_i,
              "main" => {
                "temp" => 24,
                "temp_min" => 20,
                "temp_max" => 28
              },
              "weather" => [
                { "description" => ["clear sky", "few clouds", "light rain"].sample }
              ]
            }
          end
        }
      }.to_json,
      queried_at: Time.current
    )
    
    begin
      if forecast.save
        Rails.logger.info "ForecastsController#demo: Created forecast ID: #{forecast.id}"
        redirect_to forecast_path(forecast)
      else
        Rails.logger.error "ForecastsController#demo: Failed to save forecast: #{forecast.errors.full_messages.join(', ')}"
        flash[:alert] = "Could not create demo forecast: #{forecast.errors.full_messages.join(', ')}"
        redirect_to root_path
      end
    rescue => e
      Rails.logger.error "ForecastsController#demo: Error: #{e.message}"
      flash[:alert] = "Error creating demo forecast: #{e.message}"
      redirect_to root_path
    end
  end
  
  # Display detailed forecast view
  def show
    unless @forecast
      address = params[:address]
      @forecast = FindOrCreateForecastService.call(address: address, request_ip: request.remote_ip)
      
      if @forecast.nil?
        # Log failed forecast retrieval
        Rails.logger.warn "Failed to retrieve forecast for #{address}"
        
        # Set flash message for user
        flash[:alert] = "We couldn't find weather data for '#{address}'. Please check the address or zip code and try again."
        redirect_to root_path
        return
      end
    end
    
    # Set display units (always display in local units based on location)
    @units = @forecast.display_units
    
    # Log successful forecast retrieval
    Rails.logger.info "Retrieved forecast for #{@forecast.address}"
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
  
  private
  
  def set_forecast
    @forecast = Forecast.find_by(id: params[:id]) if params[:id].present?
  end
end
