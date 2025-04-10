class ForecastsController < ApplicationController
  # GET /forecasts - Display search form
  def index
    # Initialize empty search form
    @address = params[:address]
    # Get temperature units preference using service
    @temperature_units = temperature_units
    
    # If address is provided, search for forecast
    if @address.present?
      begin
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
    elsif params[:address].is_a?(String) && params[:address].empty?
      # Handle empty address submission explicitly
      flash.now[:alert] = "Please provide an address to search for forecasts"
      render :index, status: :unprocessable_entity
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
  
  # Helper method to render error responses consistently
  def render_error_response(error_response)
    flash.now[:alert] = error_response[:error]
    render :index, status: error_response[:status]
  end
end
