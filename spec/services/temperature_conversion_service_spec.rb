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
  end
end
