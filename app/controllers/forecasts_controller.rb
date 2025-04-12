# frozen_string_literal: true

class ForecastsController < ApplicationController
  # Display forecast search form and results
  def index
    # Home page with search form
    @recent_forecasts = Forecast.recent.limit(5)
    
    # Handle search if address is provided
    if params[:address].present?
      search_for_forecast(params[:address])
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
    
    search_for_forecast(address)
  end
  
  private
  
  # Shared method for searching forecasts
  def search_for_forecast(address)
    @address = address
    
    begin
      @forecast = FindOrCreateForecastService.call(address: @address, request_ip: request.remote_ip)
      
      if @forecast.nil?
        handle_forecast_not_found
        return
      end
      
      @units = @forecast.display_units
      @search_query = @address
      
      # Always render the index template with results
      render :index
    rescue ApiClientBase::RateLimitExceededError
      handle_error("Rate limit exceeded. Please try again later.")
    rescue ApiClientBase::AuthenticationError
      handle_error("API authentication error. Please check your API key.")
    rescue StandardError => e
      Rails.logger.error("Error in forecast search: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      handle_error("An error occurred while fetching weather data. Please try again later.")
    end
  end
  
  def handle_forecast_not_found
    flash.now[:alert] = "We couldn't find weather data for '#{@address}'. Please check the address or zip code and try again."
    @search_error = true
    @search_query = @address
    @recent_forecasts = Forecast.recent.limit(10)
    @forecast = nil
  end
  
  def handle_error(message)
    flash.now[:alert] = message
    @search_error = true
    @search_query = @address
    @recent_forecasts = Forecast.recent.limit(5)
  end
end
