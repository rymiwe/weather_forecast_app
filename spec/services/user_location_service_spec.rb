# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserLocationService do
  describe '.units_for_ip' do
    context 'with US IP addresses' do
      it 'returns imperial units' do
        # US IP address
        allow(Geocoder).to receive(:search).with('72.229.28.185').and_return([
          double(country_code: 'US')
        ])
        
        expect(UserLocationService.units_for_ip('72.229.28.185')).to eq('imperial')
      end
    end
    
    context 'with non-US IP addresses' do
      it 'returns metric units for French IP' do
        allow(Geocoder).to receive(:search).with('91.198.174.192').and_return([
          double(country_code: 'FR')
        ])
        
        expect(UserLocationService.units_for_ip('91.198.174.192')).to eq('metric')
      end
      
      it 'returns metric units for Japanese IP' do
        allow(Geocoder).to receive(:search).with('126.0.0.1').and_return([
          double(country_code: 'JP')
        ])
        
        expect(UserLocationService.units_for_ip('126.0.0.1')).to eq('metric')
      end
    end
    
    context 'with local/private IP addresses' do
      it 'returns default units for private IPs' do
        expect(UserLocationService.units_for_ip('192.168.1.1')).to eq(UserLocationService::DEFAULT_UNIT)
        expect(UserLocationService.units_for_ip('10.0.0.1')).to eq(UserLocationService::DEFAULT_UNIT)
        expect(UserLocationService.units_for_ip('172.16.0.1')).to eq(UserLocationService::DEFAULT_UNIT)
        expect(UserLocationService.units_for_ip('127.0.0.1')).to eq(UserLocationService::DEFAULT_UNIT)
      end
      
      it 'returns default units for blank IP' do
        expect(UserLocationService.units_for_ip(nil)).to eq(UserLocationService::DEFAULT_UNIT)
        expect(UserLocationService.units_for_ip('')).to eq(UserLocationService::DEFAULT_UNIT)
      end
    end
    
    context 'with geocoding errors' do
      it 'returns default units when geocoding fails' do
        allow(Geocoder).to receive(:search).with('8.8.8.8').and_raise('Geocoding error')
        
        expect(UserLocationService.units_for_ip('8.8.8.8')).to eq(UserLocationService::DEFAULT_UNIT)
      end
      
      it 'returns default units when location has no country code' do
        allow(Geocoder).to receive(:search).with('8.8.8.8').and_return([
          double(country_code: nil)
        ])
        
        expect(UserLocationService.units_for_ip('8.8.8.8')).to eq(UserLocationService::DEFAULT_UNIT)
      end
    end
  end
  
  describe '.local_ip?' do
    it 'correctly identifies local/private IPs' do
      expect(UserLocationService.local_ip?('127.0.0.1')).to be true
      expect(UserLocationService.local_ip?('10.0.0.1')).to be true
      expect(UserLocationService.local_ip?('192.168.1.1')).to be true
      expect(UserLocationService.local_ip?('172.16.0.1')).to be true
      expect(UserLocationService.local_ip?('172.31.255.255')).to be true
      expect(UserLocationService.local_ip?('::1')).to be true
      expect(UserLocationService.local_ip?('fc00::1')).to be true
      expect(UserLocationService.local_ip?('localhost')).to be true
    end
    
    it 'correctly identifies public IPs' do
      expect(UserLocationService.local_ip?('8.8.8.8')).to be false
      expect(UserLocationService.local_ip?('72.229.28.185')).to be false
      expect(UserLocationService.local_ip?('2001:4860:4860::8888')).to be false
    end
    
    it 'handles nil or empty IPs' do
      expect(UserLocationService.local_ip?(nil)).to be true
      expect(UserLocationService.local_ip?('')).to be true
    end
  end
end
