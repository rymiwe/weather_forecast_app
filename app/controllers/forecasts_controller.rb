# frozen_string_literal: true

class ForecastsController < ApplicationController
  # Display forecast search form and results
  def index
    # Home page with search form
    
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
      respond_to do |format|
        format.html do 
          flash[:alert] = "Please provide an address"
          redirect_to root_path
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "forecast_results",
            partial: "forecasts/error",
            locals: { error: "Please provide an address" }
          )
        end
      end
      return
    end
    
    # Clear any existing flash messages to prevent duplicates
    flash.clear
    
    search_for_forecast(address)
    
    # If no rendering happened in search_for_forecast, render index as fallback
    render :index unless performed?
  end
  
  # Refreshes the forecast for a specific address via Turbo
  def refresh
    address = params[:address]
    
    if address.blank?
      Rails.logger.warn "ForecastsController#refresh: Blank address provided"
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Please provide an address to refresh" }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "forecast_results",
            partial: "forecasts/error",
            locals: { error: "Please provide an address to refresh" }
          )
        end
      end
      return
    end
    
    # Find existing forecasts for this address
    existing_forecast = Forecast.find_by(address: address)
    
    # Delete existing forecast to force fresh API call
    existing_forecast&.destroy
    
    # Clear any existing flash messages to prevent duplicates
    flash.clear
    
    # Search for fresh forecast data
    search_for_forecast(address)
    
    # Rendering is handled in search_for_forecast
    render :index unless performed?
  end
  
  # Legacy method for refreshing cache based on forecast ID
  # Kept for backwards compatibility
  def refresh_cache
    @forecast = Forecast.find_by(id: params[:id])
    
    if @forecast.nil?
      flash[:alert] = "Forecast not found"
      redirect_to forecasts_path
      return
    end
    
    # Get address to use for re-querying
    address = @forecast.address
    
    # Delete the existing forecast to force a fresh API call
    @forecast.destroy
    
    # Get fresh forecast data
    @forecast = FindOrCreateForecastService.call(address: address, request_ip: request.remote_ip)
    
    if @forecast.nil?
      flash[:alert] = "Unable to refresh forecast data. Please try again."
      redirect_to forecasts_path
      return
    end
    
    flash[:notice] = "Forecast data refreshed successfully!"
    # Redirect to search results instead of show page since that's what we use
    redirect_to forecasts_path(address: address)
  rescue StandardError => e
    Rails.logger.error "Error refreshing forecast: #{e.message}"
    flash[:alert] = "Error refreshing forecast: #{e.message}"
    redirect_to forecasts_path
  end
  
  private
  
  # Shared method for searching forecasts
  def search_for_forecast(address)
    @address = address
    @search_query = address
    
    begin
      @forecast = FindOrCreateForecastService.call(address: @address, request_ip: request.remote_ip)
      
      if @forecast.nil?
        handle_forecast_not_found
        return
      end
      
      # Store the original user query
      @forecast.user_query = address
      
      @units = @forecast.display_units
      
      # Respond with appropriate format
      respond_to do |format|
        format.html { render :index }
        format.turbo_stream { render :index }
      end
    rescue Faraday::ClientError => e
      if e.response && e.response[:status] == 429
        handle_error("Rate limit exceeded. Please try again later.")
      else
        handle_error("API client error: #{e.message}")
      end
    rescue Faraday::ConnectionFailed => e
      handle_error("Connection failed. Please check your internet connection and try again.")
    rescue Faraday::TimeoutError => e
      handle_error("Request timed out. Please try again later.")
    rescue StandardError => e
      Rails.logger.error("Error in forecast search: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      handle_error("An error occurred while fetching weather data. Please try again later.")
    end
  end
  
  # Handle error responses with format awareness
  def handle_error(message)
    @error = message
    
    respond_to do |format|
      format.html do
        flash.now[:alert] = message
        render :index, status: :unprocessable_entity
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "forecast_results",
          partial: "forecasts/error",
          locals: { error: message }
        )
      end
    end
  end
  
  # Handle case when forecast is not found
  def handle_forecast_not_found
    handle_error("Unable to find weather data for '#{@address}'. Please check the address and try again.")
  end
end
