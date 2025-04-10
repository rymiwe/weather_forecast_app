# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TemperatureConversionService do
  describe '.fahrenheit_to_celsius' do
    it 'correctly converts freezing temperature' do
      expect(TemperatureConversionService.fahrenheit_to_celsius(32)).to eq(0)
    end
    
    it 'correctly converts boiling temperature' do
      expect(TemperatureConversionService.fahrenheit_to_celsius(212)).to eq(100)
    end
    
    it 'correctly converts room temperature' do
      expect(TemperatureConversionService.fahrenheit_to_celsius(72)).to eq(22)
    end
    
    it 'correctly converts negative temperatures' do
      expect(TemperatureConversionService.fahrenheit_to_celsius(-4)).to eq(-20)
    end
    
    it 'properly rounds temperatures' do
      # 59°F is exactly 15.0°C
      expect(TemperatureConversionService.fahrenheit_to_celsius(59)).to eq(15)
      
      # 61°F is approximately 16.11°C, which should round to 16°C
      expect(TemperatureConversionService.fahrenheit_to_celsius(61)).to eq(16)
      
      # 33°F is approximately 0.56°C, which should round to 1°C
      expect(TemperatureConversionService.fahrenheit_to_celsius(33)).to eq(1)
    end
    
    it 'handles floating point precision correctly' do
      # Edge cases where floating point arithmetic could cause issues
      expect(TemperatureConversionService.fahrenheit_to_celsius(86)).to eq(30)
      expect(TemperatureConversionService.fahrenheit_to_celsius(14)).to eq(-10)
    end
    
    it 'returns integer results' do
      # Verify the method always returns integers
      expect(TemperatureConversionService.fahrenheit_to_celsius(98.6)).to be_an(Integer)
      expect(TemperatureConversionService.fahrenheit_to_celsius(32)).to be_an(Integer)
    end
  end
  
  describe '.celsius_to_fahrenheit' do
    it 'correctly converts freezing temperature' do
      expect(TemperatureConversionService.celsius_to_fahrenheit(0)).to eq(32)
    end
    
    it 'correctly converts boiling temperature' do
      expect(TemperatureConversionService.celsius_to_fahrenheit(100)).to eq(212)
    end
    
    it 'correctly converts room temperature' do
      expect(TemperatureConversionService.celsius_to_fahrenheit(22)).to eq(72)
    end
    
    it 'correctly converts negative temperatures' do
      expect(TemperatureConversionService.celsius_to_fahrenheit(-20)).to eq(-4)
    end
    
    it 'properly rounds temperatures' do
      # 15.6°C is exactly 60.08°F, which should round to 60°F
      expect(TemperatureConversionService.celsius_to_fahrenheit(15.6)).to eq(60)
      
      # 20.6°C is exactly 69.08°F, which should round to 69°F
      expect(TemperatureConversionService.celsius_to_fahrenheit(20.6)).to eq(69)
      
      # 23.9°C is exactly 75.02°F, which should round to 75°F
      expect(TemperatureConversionService.celsius_to_fahrenheit(23.9)).to eq(75)
    end
    
    it 'handles floating point precision correctly' do
      # Edge cases where floating point arithmetic could cause issues
      expect(TemperatureConversionService.celsius_to_fahrenheit(16.7)).to eq(62)
      expect(TemperatureConversionService.celsius_to_fahrenheit(33.3)).to eq(92)
    end
    
    it 'returns integer results' do
      # Verify the method always returns integers
      expect(TemperatureConversionService.celsius_to_fahrenheit(12.3)).to be_an(Integer)
      expect(TemperatureConversionService.celsius_to_fahrenheit(30)).to be_an(Integer)
    end
  end
  
  describe '.convert' do
    it 'returns the same value when from and to units are the same' do
      expect(TemperatureConversionService.convert(75, from: 'imperial', to: 'imperial')).to eq(75)
      expect(TemperatureConversionService.convert(25, from: 'metric', to: 'metric')).to eq(25)
    end
    
    it 'converts from imperial to metric' do
      expect(TemperatureConversionService.convert(68, from: 'imperial', to: 'metric')).to eq(20)
    end
    
    it 'converts from metric to imperial' do
      expect(TemperatureConversionService.convert(20, from: 'metric', to: 'imperial')).to eq(68)
    end
    
    it 'handles nil temperature values' do
      expect(TemperatureConversionService.convert(nil, from: 'imperial', to: 'metric')).to be_nil
    end
    
    it 'returns temperature as-is when units are unknown' do
      expect(TemperatureConversionService.convert(75, from: 'unknown', to: 'metric')).to eq(75)
      expect(TemperatureConversionService.convert(25, from: 'metric', to: 'unknown')).to eq(25)
    end
    
    it 'handles case insensitivity for unit parameters' do
      expect(TemperatureConversionService.convert(20, from: 'Metric', to: 'Imperial')).to eq(68)
      expect(TemperatureConversionService.convert(68, from: 'IMPERIAL', to: 'METRIC')).to eq(20)
    end
    
    it 'handles string temperature values' do
      expect(TemperatureConversionService.convert('68', from: 'imperial', to: 'metric')).to eq(20)
      expect(TemperatureConversionService.convert('20', from: 'metric', to: 'imperial')).to eq(68)
    end
    
    it 'handles both from and to being unknown' do
      expect(TemperatureConversionService.convert(75, from: 'unknown', to: 'unknown')).to eq(75)
    end
    
    it 'handles extreme temperatures' do
      # Very hot: 120°F is about 49°C
      expect(TemperatureConversionService.convert(120, from: 'imperial', to: 'metric')).to eq(49)
      
      # Very cold: -40°F is -40°C (they meet at this point)
      expect(TemperatureConversionService.convert(-40, from: 'imperial', to: 'metric')).to eq(-40)
    end
  end
end
