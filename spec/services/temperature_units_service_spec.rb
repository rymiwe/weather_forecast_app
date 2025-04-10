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
    end
    
    context 'with config default' do
      it 'returns the config default when no session preference exists' do
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return('imperial')
        result = TemperatureUnitsService.determine_units(session: {})
        expect(result).to eq('imperial')
      end
    end
    
    context 'with IP-based detection' do
      before do
        # No session preference or config default
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return(nil)
      end
      
      it 'uses IP-based detection for US IPs' do
        allow(UserLocationService).to receive(:units_for_ip).with('1.2.3.4').and_return('imperial')
        result = TemperatureUnitsService.determine_units(ip_address: '1.2.3.4')
        expect(result).to eq('imperial')
      end
      
      it 'uses IP-based detection for non-US IPs' do
        allow(UserLocationService).to receive(:units_for_ip).with('5.6.7.8').and_return('metric')
        result = TemperatureUnitsService.determine_units(ip_address: '5.6.7.8')
        expect(result).to eq('metric')
      end
      
      it 'defaults to imperial when IP is blank' do
        result = TemperatureUnitsService.determine_units(ip_address: nil)
        expect(result).to eq('imperial')
      end
    end
    
    context 'with priority order' do
      it 'prioritizes session over config and IP' do
        # Set all three options
        session = { temperature_units: 'metric' }
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return('imperial')
        allow(UserLocationService).to receive(:units_for_ip).and_return('imperial')
        
        # Session should win
        result = TemperatureUnitsService.determine_units(session: session, ip_address: '1.2.3.4')
        expect(result).to eq('metric')
      end
      
      it 'prioritizes config over IP when no session' do
        # Set config and IP options
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return('metric')
        allow(UserLocationService).to receive(:units_for_ip).and_return('imperial')
        
        # Config should win
        result = TemperatureUnitsService.determine_units(session: {}, ip_address: '1.2.3.4')
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
      
      it 'handles invalid session values and falls back to defaults' do
        # Test with invalid unit in session
        session = { temperature_units: 'kelvin' } # not a supported unit
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return('imperial')
        
        result = TemperatureUnitsService.determine_units(session: session)
        # Should fall back to config default
        expect(result).to eq('imperial')
      end
      
      it 'handles empty session hash' do
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return('metric')
        result = TemperatureUnitsService.determine_units(session: {})
        expect(result).to eq('metric')
      end
      
      it 'handles nil session' do
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return('imperial')
        result = TemperatureUnitsService.determine_units(session: nil)
        expect(result).to eq('imperial')
      end
      
      it 'handles malformed IP addresses' do
        # No session or config, invalid IP
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return(nil)
        allow(UserLocationService).to receive(:units_for_ip).with('invalid-ip').and_return(nil)
        
        result = TemperatureUnitsService.determine_units(ip_address: 'invalid-ip')
        # Should default to imperial as fallback
        expect(result).to eq('imperial')
      end
      
      it 'handles unexpected errors in IP lookup' do
        # No session or config, IP service raises error
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return(nil)
        allow(UserLocationService).to receive(:units_for_ip).with('1.2.3.4').and_raise(StandardError.new("API error"))
        
        # Should handle the error and return default fallback
        result = TemperatureUnitsService.determine_units(ip_address: '1.2.3.4')
        expect(result).to eq('imperial')
      end
      
      it 'handles all inputs being nil' do
        # No session, config, or IP
        allow(Rails.configuration.x.weather).to receive(:default_unit).and_return(nil)
        
        result = TemperatureUnitsService.determine_units
        # Should return default imperial as ultimate fallback
        expect(result).to eq('imperial')
      end
    end
  end
end
