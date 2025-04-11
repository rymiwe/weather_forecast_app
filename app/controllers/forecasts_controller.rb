# frozen_string_literal: true

class ForecastsController < ApplicationController
  before_action :set_forecast, only: [:show]
  
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
