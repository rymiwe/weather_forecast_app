class ForecastsController < ApplicationController
  # GET /forecasts - Display search form
  def index
    @forecast = nil
    @address = params[:address]
    
    if forecast_params[:address].present?
      # Clear any existing forecast
      session[:forecast_id] = nil
      
      # Make forecasts always use the location's preferred units
      @forecast = ForecastRetrievalService.new(
        address: forecast_params[:address], 
        units: nil # Will be determined by location
      ).call
      
      if @forecast.persisted?
        session[:forecast_id] = @forecast.id
        
        # Set temperature units based on location (e.g., imperial for US, metric elsewhere)
        session[:temperature_units] = @forecast.location_based_units
      end
    elsif session[:forecast_id].present?
      @forecast = Forecast.find_by(id: session[:forecast_id])
    end
    
    # If address is provided, search for forecast
    if @forecast.present?
      # Set flash messages for errors
      flash.now[:alert] = "Unable to find location" if @forecast.nil?
      
      # Render the forecast partial via Turbo Stream if it's an AJAX request
      respond_to do |format|
        format.html # Render the default index template
        format.turbo_stream
      end
    end
  rescue Net::HTTPClientException, Net::HTTPServerException, Net::HTTPFatalError, Timeout::Error, Errno::ECONNREFUSED => e
    # Handle network and HTTP errors
    error_response = ErrorHandlingService.handle_api_error(e)
    render_error_response(error_response)
  rescue JSON::ParserError => e
    # Handle JSON parsing errors
    error_response = ErrorHandlingService.handle_api_error(e)
    render_error_response(error_response)
  rescue ErrorHandlingService::RateLimitError => e
    # Handle rate limiting
    error_response = ErrorHandlingService.handle_api_error(e)
    render_error_response(error_response)
  rescue ErrorHandlingService::ConfigurationError => e
    # Handle configuration errors
    error_response = ErrorHandlingService.handle_api_error(e)
    render_error_response(error_response)
  rescue ArgumentError => e
    # Handle invalid input errors
    flash.now[:alert] = e.message
    render :index, status: :unprocessable_entity
  rescue StandardError => e
    # Handle any other unexpected errors
    error_response = ErrorHandlingService.handle_api_error(e)
    render_error_response(error_response)
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
  
  # Helper method to render error responses consistently
  def render_error_response(error_response)
    flash.now[:alert] = error_response[:error]
    render :index, status: error_response[:status]
  end
  
  # Render an error response
  def render_error_response(error_response)
    flash.now[:alert] = error_response[:message] || "An unexpected error occurred."
    render :index, status: error_response[:status] || :internal_server_error
  end
  
  # Permitted forecast parameters
  def forecast_params
    params.permit(:address)
  end
  
  # Get temperature units from session or default
  def temperature_units
    session[:temperature_units] || Rails.configuration.x.weather.default_unit
  end
end
