# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forecast, type: :model do
  describe '#display_units' do
    context 'with US zip codes' do
      it 'returns imperial units for valid US zip codes' do
        forecast = Forecast.new(zip_code: '97214', address: 'Portland, OR')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(zip_code: '10001', address: 'New York, NY')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(zip_code: '90210', address: 'Beverly Hills, CA')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(zip_code: '60601', address: 'Chicago, IL')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
      end
      
      it 'does not identify non-US format postal codes as US' do
        # Canadian postal code format
        forecast = Forecast.new(zip_code: 'V6B 4N6', address: 'Vancouver, BC, Canada')
        allow(forecast).to receive(:api_country_code).and_return("CA")
        expect(forecast.display_units).to eq('metric')
        
        # UK postal code format
        forecast = Forecast.new(zip_code: 'SW1A 1AA', address: 'London, UK')
        allow(forecast).to receive(:api_country_code).and_return("GB")
        expect(forecast.display_units).to eq('metric')
        
        # Japanese postal code format
        forecast = Forecast.new(zip_code: '100-0001', address: 'Tokyo, Japan')
        allow(forecast).to receive(:api_country_code).and_return("JP")
        expect(forecast.display_units).to eq('metric')
      end
    end
    
    context 'with address-based detection for US locations' do
      it 'returns imperial units for US city names' do
        # No zip code but US city names should use imperial
        forecast = Forecast.new(address: 'Los Angeles, California')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'Miami, Florida')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'Portland, Oregon')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'Dallas, Texas')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
      end
      
      it 'returns imperial units for US state abbreviations' do
        forecast = Forecast.new(address: 'Portland, OR')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'Miami, FL')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'Chicago, IL')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
      end
      
      it 'returns imperial units for addresses containing USA or America' do
        forecast = Forecast.new(address: 'Springfield, USA')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'Anytown, America')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'Smallville, United States')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'Gotham, U.S.A.')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
      end
    end
    
    context 'with non-US locations' do
      it 'returns metric units for European cities' do
        forecast = Forecast.new(address: 'London, UK')
        allow(forecast).to receive(:api_country_code).and_return("GB")
        expect(forecast.display_units).to eq('metric')
        
        forecast = Forecast.new(address: 'Paris, France')
        allow(forecast).to receive(:api_country_code).and_return("FR")
        expect(forecast.display_units).to eq('metric')
        
        forecast = Forecast.new(address: 'Berlin, Germany')
        allow(forecast).to receive(:api_country_code).and_return("DE")
        expect(forecast.display_units).to eq('metric')
      end
      
      it 'returns metric units for Asian cities' do
        forecast = Forecast.new(address: 'Tokyo, Japan')
        allow(forecast).to receive(:api_country_code).and_return("JP")
        expect(forecast.display_units).to eq('metric')
        
        forecast = Forecast.new(address: 'Beijing, China')
        allow(forecast).to receive(:api_country_code).and_return("CN")
        expect(forecast.display_units).to eq('metric')
        
        forecast = Forecast.new(address: 'Mumbai, India')
        allow(forecast).to receive(:api_country_code).and_return("IN")
        expect(forecast.display_units).to eq('metric')
      end
      
      it 'returns metric units for Australian and NZ cities' do
        forecast = Forecast.new(address: 'Sydney, Australia')
        allow(forecast).to receive(:api_country_code).and_return("AU")
        expect(forecast.display_units).to eq('metric')
        
        forecast = Forecast.new(address: 'Auckland, New Zealand')
        allow(forecast).to receive(:api_country_code).and_return("NZ")
        expect(forecast.display_units).to eq('metric')
      end
      
      it 'returns metric units for South American cities' do
        forecast = Forecast.new(address: 'Rio de Janeiro, Brazil')
        allow(forecast).to receive(:api_country_code).and_return("BR")
        expect(forecast.display_units).to eq('metric')
        
        forecast = Forecast.new(address: 'Buenos Aires, Argentina')
        allow(forecast).to receive(:api_country_code).and_return("AR")
        expect(forecast.display_units).to eq('metric')
      end
      
      it 'returns metric units for African cities' do
        forecast = Forecast.new(address: 'Cairo, Egypt')
        allow(forecast).to receive(:api_country_code).and_return("EG")
        expect(forecast.display_units).to eq('metric')
        
        forecast = Forecast.new(address: 'Cape Town, South Africa')
        allow(forecast).to receive(:api_country_code).and_return("ZA")
        expect(forecast.display_units).to eq('metric')
      end
      
      it 'returns metric units for Canadian cities despite proximity to US' do
        forecast = Forecast.new(address: 'Toronto, Canada')
        allow(forecast).to receive(:api_country_code).and_return("CA")
        expect(forecast.display_units).to eq('metric')
        
        forecast = Forecast.new(address: 'Vancouver, BC')
        allow(forecast).to receive(:api_country_code).and_return("CA")
        expect(forecast.display_units).to eq('metric')
      end
    end
    
    context 'with edge cases' do
      it 'defaults to metric units when no location information is provided' do
        forecast = Forecast.new
        allow(forecast).to receive(:api_country_code).and_return(nil)
        expect(forecast.display_units).to eq('metric')
      end
      
      it 'handles case-insensitive matching' do
        forecast = Forecast.new(address: 'PORTLAND, OREGON')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'london, uk')
        allow(forecast).to receive(:api_country_code).and_return("GB")
        expect(forecast.display_units).to eq('metric')
      end
      
      it 'handles locations with multiple word variants' do
        forecast = Forecast.new(address: 'New York City, United States')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
        
        forecast = Forecast.new(address: 'NYC, NY')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
      end
      
      it 'properly handles locations that might be confused' do
        # London, Ontario, Canada vs London, UK
        # Since our implementation is basic, this would likely return imperial
        # because it matches 'london', but in a real app would be more sophisticated
        forecast = Forecast.new(address: 'London, Ontario, Canada')
        allow(forecast).to receive(:api_country_code).and_return("CA")
        expect(forecast.display_units).to eq('metric')
        
        # Paris, Texas (US) vs Paris, France
        forecast = Forecast.new(address: 'Paris, TX, USA')
        allow(forecast).to receive(:api_country_code).and_return("US")
        expect(forecast.display_units).to eq('imperial')
      end
    end
  end
end
