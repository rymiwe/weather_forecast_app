# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ZipCodeExtractionService do
  describe '.extract_from_address' do
    it 'extracts a basic 5-digit zip code' do
      expect(ZipCodeExtractionService.extract_from_address('123 Main St, Seattle, WA 98101')).to eq('98101')
    end
    
    it 'extracts a ZIP+4 format code' do
      expect(ZipCodeExtractionService.extract_from_address('123 Main St, Seattle, WA 98101-1234')).to eq('98101-1234')
    end
    
    it 'returns nil when no zip code is present' do
      expect(ZipCodeExtractionService.extract_from_address('123 Main St, Seattle, WA')).to be_nil
    end
    
    it 'returns nil when address is nil' do
      expect(ZipCodeExtractionService.extract_from_address(nil)).to be_nil
    end
    
    it 'returns nil when address is blank' do
      expect(ZipCodeExtractionService.extract_from_address('')).to be_nil
    end
    
    it 'extracts zip code from the middle of text' do
      expect(ZipCodeExtractionService.extract_from_address('Send mail to Seattle 98101 Washington')).to eq('98101')
    end
  end
  
  describe '.extract_from_location_data' do
    it 'extracts zip code from zip key' do
      data = { 'zip' => '98101' }
      expect(ZipCodeExtractionService.extract_from_location_data(data)).to eq('98101')
    end
    
    it 'extracts zip code from symbol zip key' do
      data = { zip: '98101' }
      expect(ZipCodeExtractionService.extract_from_location_data(data)).to eq('98101')
    end
    
    it 'extracts postal code from postal_code key' do
      data = { 'postal_code' => '98101' }
      expect(ZipCodeExtractionService.extract_from_location_data(data)).to eq('98101')
    end
    
    it 'extracts from local_names structure' do
      data = { 'local_names' => { 'postcode' => '98101' } }
      expect(ZipCodeExtractionService.extract_from_location_data(data)).to eq('98101')
    end
    
    it 'extracts from local_names with custom key' do
      data = { 'local_names' => { 'zip' => '98101' } }
      expect(ZipCodeExtractionService.extract_from_location_data(data, postal_code_key: :zip)).to eq('98101')
    end
    
    it 'extracts from formatted_address as fallback' do
      data = { 'formatted_address' => '123 Main St, Seattle, WA 98101' }
      expect(ZipCodeExtractionService.extract_from_location_data(data)).to eq('98101')
    end
    
    it 'returns nil for non-hash input' do
      expect(ZipCodeExtractionService.extract_from_location_data('not a hash')).to be_nil
    end
    
    it 'returns nil when no postal code is found' do
      data = { 'city' => 'Seattle', 'state' => 'WA' }
      expect(ZipCodeExtractionService.extract_from_location_data(data)).to be_nil
    end
  end
end
