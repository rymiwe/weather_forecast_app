# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorHandlingService do
  describe '.handle_rate_limit_exceeded' do
    it 'logs a warning message' do
      service_name = 'openweathermap'
      
      # Expect a warning to be logged
      expect(Rails.logger).to receive(:warn).with(/Rate limit exceeded for #{service_name}/)
      
      # Call method and expect exception
      expect { 
        ErrorHandlingService.handle_rate_limit_exceeded(service_name)
      }.to raise_error(ErrorHandlingService::RateLimitExceededError)
    end
    
    it 'raises a RateLimitExceededError with the default message' do
      expect { 
        ErrorHandlingService.handle_rate_limit_exceeded('test-service')
      }.to raise_error(ErrorHandlingService::RateLimitExceededError, ErrorHandlingService::DEFAULT_RATE_LIMIT_MESSAGE)
    end
    
    it 'raises a RateLimitExceededError with a custom message when provided' do
      custom_message = 'Custom rate limit message'
      
      expect { 
        ErrorHandlingService.handle_rate_limit_exceeded('test-service', custom_message)
      }.to raise_error(ErrorHandlingService::RateLimitExceededError, custom_message)
    end
  end
end
