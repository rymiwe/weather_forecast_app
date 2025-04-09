class ForecastsController < ApplicationController
  # GET /forecasts - Display search form
  def index
    # Initialize empty search form
    @address = params[:address]
    # Get temperature units preference using service
    @temperature_units = temperature_units
    
    # If address is provided, search for forecast
    if @address.present?
      # Retrieve forecast using the service object
      @forecast = ForecastRetrievalService.retrieve(
        @address, 
        units: @temperature_units,
        request_ip: request.remote_ip
      )
      
      # Set flash messages for errors
      flash.now[:alert] = "Unable to find location" if @forecast.nil?
      
      # Render the forecast partial via Turbo Stream if it's an AJAX request
      respond_to do |format|
        format.html # Render the default index template
        format.turbo_stream
      end
    end
  end

  # GET /forecasts/:id - Display a specific forecast
  def show
    @forecast = Forecast.find(params[:id])
    # Set temperature units preference if provided
    session[:temperature_units] = params[:units] if params[:units].present?
    # Get current temperature units
    @temperature_units = temperature_units
  rescue ActiveRecord::RecordNotFound
    redirect_to forecasts_path, alert: "Forecast not found"
  end
  
  private
  
end
