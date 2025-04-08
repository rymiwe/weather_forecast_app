# This file contains all the record creation needed to seed the database with default values.
# It can be loaded with the bin/rails db:seed command.

# Sample forecasts for demonstration purposes
sample_forecasts = [
  {
    address: "123 Main St, New York, NY 10001",
    zip_code: "10001",
    current_temp: 72.5,
    high_temp: 78.0,
    low_temp: 65.0,
    conditions: "Partly Cloudy",
    extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":75,"low":62,"conditions":["partly cloudy"]},{"date":"2025-04-09","day_name":"Wednesday","high":77,"low":64,"conditions":["sunny"]},{"date":"2025-04-10","day_name":"Thursday","high":79,"low":67,"conditions":["sunny"]},{"date":"2025-04-11","day_name":"Friday","high":76,"low":65,"conditions":["partly cloudy"]},{"date":"2025-04-12","day_name":"Saturday","high":74,"low":63,"conditions":["cloudy"]}]',
    queried_at: 2.minutes.ago
  },
  {
    address: "456 Michigan Ave, Chicago, IL 60611",
    zip_code: "60611",
    current_temp: 68.0,
    high_temp: 73.0,
    low_temp: 59.0,
    conditions: "Sunny",
    extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":72,"low":58,"conditions":["sunny"]},{"date":"2025-04-09","day_name":"Wednesday","high":74,"low":60,"conditions":["partly cloudy"]},{"date":"2025-04-10","day_name":"Thursday","high":71,"low":57,"conditions":["partly cloudy"]},{"date":"2025-04-11","day_name":"Friday","high":69,"low":55,"conditions":["cloudy"]},{"date":"2025-04-12","day_name":"Saturday","high":70,"low":54,"conditions":["rain"]}]',
    queried_at: 5.minutes.ago
  },
  {
    address: "789 Market St, San Francisco, CA 94103",
    zip_code: "94103",
    current_temp: 65.0,
    high_temp: 70.0,
    low_temp: 55.0,
    conditions: "Foggy",
    extended_forecast: '[{"date":"2025-04-08","day_name":"Tuesday","high":68,"low":54,"conditions":["foggy"]},{"date":"2025-04-09","day_name":"Wednesday","high":69,"low":56,"conditions":["partly cloudy"]},{"date":"2025-04-10","day_name":"Thursday","high":67,"low":53,"conditions":["foggy"]},{"date":"2025-04-11","day_name":"Friday","high":66,"low":52,"conditions":["foggy"]},{"date":"2025-04-12","day_name":"Saturday","high":70,"low":55,"conditions":["partly cloudy"]}]',
    queried_at: 10.minutes.ago
  }
]

# Create the sample forecasts
puts "Creating sample forecast data..."
sample_forecasts.each do |forecast_data|
  forecast = Forecast.create!(forecast_data)
  puts "Created forecast for #{forecast.address}"
end

puts "Seeding completed successfully!"
