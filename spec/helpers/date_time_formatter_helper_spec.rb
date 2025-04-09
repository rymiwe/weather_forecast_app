# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DateTimeFormatterHelper, type: :helper do
  describe '#format_full_datetime' do
    it 'formats a datetime object correctly' do
      # Fix the datetime to avoid test flakiness
      datetime = Time.zone.local(2025, 4, 9, 14, 30, 0)
      expect(helper.format_full_datetime(datetime)).to eq('Wednesday, April 09, 2025 at 02:30 PM')
    end
    
    it 'returns an empty string for nil input' do
      expect(helper.format_full_datetime(nil)).to eq('')
    end
  end
  
  describe '#format_forecast_date' do
    it 'formats a date object correctly' do
      date = Date.new(2025, 4, 9)
      expect(helper.format_forecast_date(date)).to eq('2025-04-09')
    end
    
    it 'formats a datetime object correctly' do
      datetime = Time.zone.local(2025, 4, 9, 14, 30, 0)
      expect(helper.format_forecast_date(datetime)).to eq('2025-04-09')
    end
    
    it 'returns an empty string for nil input' do
      expect(helper.format_forecast_date(nil)).to eq('')
    end
  end
  
  describe '#format_day_name' do
    it 'formats a date object correctly' do
      date = Date.new(2025, 4, 9) # A Wednesday
      expect(helper.format_day_name(date)).to eq('Wednesday')
    end
    
    it 'parses and formats a string date correctly' do
      expect(helper.format_day_name('2025-04-09')).to eq('Wednesday')
    end
    
    it 'returns the original string if it cannot be parsed' do
      expect(helper.format_day_name('Not a date')).to eq('Not a date')
    end
    
    it 'returns an empty string for nil input' do
      expect(helper.format_day_name(nil)).to eq('')
    end
  end
  
  describe '#format_cache_time' do
    it 'formats a time object correctly' do
      time = Time.zone.local(2025, 4, 9, 15, 10, 0)
      expect(helper.format_cache_time(time)).to eq('03:10 PM')
    end
    
    it 'returns an empty string for nil input' do
      expect(helper.format_cache_time(nil)).to eq('')
    end
  end
end
