# frozen_string_literal: true

# Service for converting between temperature units
# Extracted to follow DRY principles across the application
class TemperatureConversionService
  # Convert temperature from Fahrenheit to Celsius
  # @param fahrenheit [Float, Integer] Temperature in Fahrenheit
  # @return [Integer] Temperature in Celsius, rounded to nearest integer
  def self.fahrenheit_to_celsius(fahrenheit)
    return nil if fahrenheit.nil?
    ((fahrenheit - 32) * 5.0 / 9.0).round
  end
  
  # Convert temperature from Celsius to Fahrenheit
  # @param celsius [Integer] Temperature in Celsius
  # @return [Integer] Temperature in Fahrenheit, rounded to nearest integer
  def self.celsius_to_fahrenheit(celsius)
    return nil if celsius.nil?
    ((celsius * 9.0 / 5.0) + 32).round
  end
  
  # Convert temperature based on source and target units
  # @param temperature [Float, Integer] Temperature value to convert
  # @param from [String] Source unit ('imperial' or 'metric')
  # @param to [String] Target unit ('imperial' or 'metric')
  # @return [Integer] Converted temperature value
  def self.convert(temperature, from:, to:)
    return temperature if from == to || !temperature
    
    if from == 'imperial' && to == 'metric'
      fahrenheit_to_celsius(temperature)
    elsif from == 'metric' && to == 'imperial'
      celsius_to_fahrenheit(temperature)
    else
      temperature # No conversion needed
    end
  end
end
