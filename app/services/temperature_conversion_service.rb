# frozen_string_literal: true

# Service for converting between temperature units
# Extracted to follow DRY principles across the application
class TemperatureConversionService
  # Convert temperature from Fahrenheit to Celsius
  # @param fahrenheit [Float] Temperature in Fahrenheit
  # @return [Float] Temperature in Celsius, rounded to one decimal
  def self.fahrenheit_to_celsius(fahrenheit)
    ((fahrenheit - 32) * 5.0 / 9.0).round(1)
  end
  
  # Convert temperature from Celsius to Fahrenheit
  # @param celsius [Float] Temperature in Celsius
  # @return [Float] Temperature in Fahrenheit, rounded to one decimal
  def self.celsius_to_fahrenheit(celsius)
    ((celsius * 9.0 / 5.0) + 32).round(1)
  end
  
  # Convert temperature based on source and target units
  # @param temperature [Float] Temperature value to convert
  # @param from [String] Source unit ('imperial' or 'metric')
  # @param to [String] Target unit ('imperial' or 'metric')
  # @return [Float] Converted temperature value
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
