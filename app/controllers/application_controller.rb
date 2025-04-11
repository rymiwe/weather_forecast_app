class ApplicationController < ActionController::Base
  # Make temperature_units available to all controllers and views
  helper_method :temperature_units
  
  # Return the appropriate temperature units based on location
  def temperature_units
    # Units can be explicitly requested via params
    if params[:units].present?
      return params[:units].downcase if ['metric', 'imperial'].include?(params[:units].downcase)
    end
    
    # Default to location-based units or metric as fallback
    @current_forecast&.location_based_units || Rails.configuration.x.weather.default_unit
  end
end
