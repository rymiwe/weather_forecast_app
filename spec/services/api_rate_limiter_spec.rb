# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiRateLimiter do
  before(:each) do
    # Reset the rate limiter before each test
    ApiRateLimiter.reset!
  end
  
  describe '.allow_request?' do
    it 'allows requests within the rate limit' do
      # Set the max requests to 3 for this test
      allow(Rails.configuration.x.weather).to receive(:max_requests_per_minute).and_return(3)
      
      # First 3 requests should be allowed
      expect(ApiRateLimiter.allow_request?('openweathermap')).to be true
      expect(ApiRateLimiter.allow_request?('openweathermap')).to be true
      expect(ApiRateLimiter.allow_request?('openweathermap')).to be true
      
      # 4th request should be denied
      expect(ApiRateLimiter.allow_request?('openweathermap')).to be false
    end
    
    it 'tracks different services separately' do
      allow(Rails.configuration.x.weather).to receive(:max_requests_per_minute).and_return(2)
      
      # Each service should have its own counter
      expect(ApiRateLimiter.allow_request?('openweathermap')).to be true
      expect(ApiRateLimiter.allow_request?('openweathermap')).to be true
      expect(ApiRateLimiter.allow_request?('openweathermap')).to be false
      
      # Different service should start fresh
      expect(ApiRateLimiter.allow_request?('geocoding')).to be true
      expect(ApiRateLimiter.allow_request?('geocoding')).to be true
      expect(ApiRateLimiter.allow_request?('geocoding')).to be false
    end
    
    it 'uses default max requests when configuration is missing' do
      # Set the configuration to nil to test default
      allow(Rails.configuration.x.weather).to receive(:max_requests_per_minute).and_return(nil)
      
      # Should use the default (60)
      60.times do
        expect(ApiRateLimiter.allow_request?('test')).to be true
      end
      
      # 61st request should be denied
      expect(ApiRateLimiter.allow_request?('test')).to be false
    end
  end
  
  describe '.current_request_count' do
    it 'returns the current request count' do
      allow(Rails.configuration.x.weather).to receive(:max_requests_per_minute).and_return(10)
      
      expect(ApiRateLimiter.current_request_count('openweathermap')).to eq(0)
      
      3.times { ApiRateLimiter.allow_request?('openweathermap') }
      
      expect(ApiRateLimiter.current_request_count('openweathermap')).to eq(3)
    end
    
    it 'returns 0 for unknown services' do
      expect(ApiRateLimiter.current_request_count('unknown_service')).to eq(0)
    end
  end
  
  describe '.reset!' do
    it 'resets all request counts' do
      allow(Rails.configuration.x.weather).to receive(:max_requests_per_minute).and_return(10)
      
      3.times { ApiRateLimiter.allow_request?('service1') }
      2.times { ApiRateLimiter.allow_request?('service2') }
      
      expect(ApiRateLimiter.current_request_count('service1')).to eq(3)
      expect(ApiRateLimiter.current_request_count('service2')).to eq(2)
      
      ApiRateLimiter.reset!
      
      expect(ApiRateLimiter.current_request_count('service1')).to eq(0)
      expect(ApiRateLimiter.current_request_count('service2')).to eq(0)
    end
  end
  
  describe 'cleanup behavior' do
    it 'handles minute boundaries correctly' do
      allow(Rails.configuration.x.weather).to receive(:max_requests_per_minute).and_return(5)
      current_minute = Time.current.strftime('%Y-%m-%d-%H-%M')
      
      # Add counts for current minute
      3.times { ApiRateLimiter.allow_request?('openweathermap') }
      
      # Simulate time change to next minute
      next_minute = (Time.current + 1.minute).strftime('%Y-%m-%d-%H-%M')
      allow(Time).to receive(:current).and_return(Time.current + 1.minute)
      
      # Counter should reset with the new minute
      expect(ApiRateLimiter.current_request_count('openweathermap')).to eq(0)
      
      # Should allow full quota in new minute
      5.times { expect(ApiRateLimiter.allow_request?('openweathermap')).to be true }
      expect(ApiRateLimiter.allow_request?('openweathermap')).to be false
    end
  end
end
