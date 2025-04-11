// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { get_forecast_days, format_temp } from "application/forecast_utilities"

// Make forecast utilities available globally
window.get_forecast_days = get_forecast_days
window.format_temp = format_temp
