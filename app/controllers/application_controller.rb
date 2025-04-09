class ApplicationController < ActionController::Base
  # Make temperature_units available to all controllers and views
  helper_method :temperature_units
  
  # Helper method to get temperature units preference
  # Uses TemperatureUnitsService for consistent unit determination
  # @return [String] 'imperial' or 'metric'
  def temperature_units
    # Store preference in session when explicitly set by the user
    if params[:units].present?
      session[:temperature_units] = params[:units]
    end
    
    # Use the service for consistent unit determination
    session[:temperature_units] ||= TemperatureUnitsService.determine_units(
      session: session, 
      ip_address: request.remote_ip
    )
  end
end
