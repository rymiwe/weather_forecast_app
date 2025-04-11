# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TemperatureUnitsService do
  describe '.determine_units' do
    context 'with session preference' do
      it 'returns the session preference when available' do
        session = { temperature_units: 'metric' }
        result = TemperatureUnitsService.determine_units(session: session)
        expect(result).to eq('metric')
      end
      
      it 'returns imperial if explicitly set in session' do
        session = { temperature_units: 'imperial' }
        result = TemperatureUnitsService.determine_units(session: session)
        expect(result).to eq('imperial')
      end
    end
    
    context 'with no session preference' do
      it 'returns metric as the default' do
        result = TemperatureUnitsService.determine_units(session: {})
        expect(result).to eq('metric')
      end
    end
    
    context 'with edge cases and error handling' do
      it 'handles case insensitivity in session values' do
        # Test with mixed case in session preference
        session = { temperature_units: 'MeTrIc' }
        result = TemperatureUnitsService.determine_units(session: session)
        expect(result).to eq('metric')
        
        session = { temperature_units: 'IMPERIAL' }
        result = TemperatureUnitsService.determine_units(session: session)
        expect(result).to eq('imperial')
      end
      
      it 'handles invalid session values and falls back to metric' do
        # Test with invalid unit in session
        session = { temperature_units: 'kelvin' } # not a supported unit
        result = TemperatureUnitsService.determine_units(session: session)
        # Should fall back to metric as default
        expect(result).to eq('metric')
      end
      
      it 'handles empty session hash' do
        result = TemperatureUnitsService.determine_units(session: {})
        expect(result).to eq('metric')
      end
      
      it 'handles nil session' do
        result = TemperatureUnitsService.determine_units(session: nil)
        expect(result).to eq('metric')
      end
      
      it 'handles all inputs being nil' do
        result = TemperatureUnitsService.determine_units
        # Should return default metric as ultimate fallback
        expect(result).to eq('metric')
      end
    end
  end
end
