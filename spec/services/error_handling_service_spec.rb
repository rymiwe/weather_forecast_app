# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorHandlingService do
  let(:context) { { request_id: 'test-123', user_ip: '127.0.0.1' } }
  
  describe '.handle_api_error' do
    it 'handles RateLimitError with correct status and message' do
      error = ErrorHandlingService::RateLimitError.new('Rate limit exceeded')
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('Rate limit exceeded')
      expect(result[:status]).to eq(:too_many_requests)
    end
    
    it 'handles ConfigurationError with correct status and message' do
      error = ErrorHandlingService::ConfigurationError.new('Missing API key')
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('Service configuration error')
      expect(result[:status]).to eq(:service_unavailable)
    end
    
    it 'handles ApiError with correct status and message' do
      error = ErrorHandlingService::ApiError.new('API returned 500')
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('API service error')
      expect(result[:status]).to eq(:bad_gateway)
    end
    
    it 'handles JSON::ParserError with correct status and message' do
      error = JSON::ParserError.new('Invalid JSON')
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('Invalid response format')
      expect(result[:status]).to eq(:unprocessable_entity)
    end
    
    it 'handles HTTP client errors' do
      error = Net::HTTPClientException.new('400 Bad Request', nil)
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('Unable to connect to external service')
      expect(result[:status]).to eq(:service_unavailable)
    end
    
    it 'handles HTTP server errors' do
      error = Net::HTTPServerException.new('500 Internal Server Error', nil)
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('Unable to connect to external service')
      expect(result[:status]).to eq(:service_unavailable)
    end
    
    it 'handles HTTP fatal errors' do
      error = Net::HTTPFatalError.new('Fatal error', nil)
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('Unable to connect to external service')
      expect(result[:status]).to eq(:service_unavailable)
    end
    
    it 'handles network errors with correct status and message' do
      error = Timeout::Error.new('Connection timeout')
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('Unable to connect')
      expect(result[:status]).to eq(:service_unavailable)
    end
    
    it 'handles Errno::ECONNREFUSED' do
      error = Errno::ECONNREFUSED.new('Connection refused')
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('Unable to connect to external service')
      expect(result[:status]).to eq(:service_unavailable)
    end
    
    it 'handles unexpected errors with fallback status and message' do
      error = StandardError.new('Unexpected error')
      
      result = ErrorHandlingService.handle_api_error(error, context)
      
      expect(result[:error]).to include('unexpected error')
      expect(result[:status]).to eq(:internal_server_error)
    end
    
    it 'logs error details' do
      error = StandardError.new('Test error')
      expect(Rails.logger).to receive(:error)
      
      ErrorHandlingService.handle_api_error(error, context)
    end
  end
  
  describe '.handle_validation_error' do
    it 'handles ActiveRecord validation errors' do
      forecast = Forecast.new
      forecast.validate # Force validation to populate errors
      
      result = ErrorHandlingService.handle_validation_error(forecast, context)
      
      expect(result[:error]).to include('blank')
      expect(result[:status]).to eq(:unprocessable_entity)
    end
    
    it 'formats validation errors' do
      record = double('ActiveRecord::Base')
      errors = double('ActiveModel::Errors')
      
      allow(record).to receive(:respond_to?).with(:errors).and_return(true)
      allow(record).to receive(:errors).and_return(errors)
      allow(errors).to receive(:full_messages).and_return(['Name cannot be blank', 'Email is invalid'])
      
      # Stub the logging method to avoid actual logging during tests
      allow(ErrorHandlingService).to receive(:log_validation_error)
      
      result = ErrorHandlingService.handle_validation_error(record, context)
      expect(result[:status]).to eq(:unprocessable_entity)
      expect(result[:error]).to include('Name cannot be blank')
      expect(result[:error]).to include('Email is invalid')
    end
    
    it 'handles non-record objects' do
      non_record = double('NonRecord')
      allow(non_record).to receive(:respond_to?).with(:errors).and_return(false)
      
      result = ErrorHandlingService.handle_validation_error(non_record, context)
      expect(result[:status]).to eq(:unprocessable_entity)
      expect(result[:error]).to include('Invalid data provided')
    end
    
    it 'provides a generic message for non-ActiveRecord objects' do
      object = Object.new
      
      result = ErrorHandlingService.handle_validation_error(object, context)
      
      expect(result[:error]).to include('Invalid data')
      expect(result[:status]).to eq(:unprocessable_entity)
    end
    
    it 'logs validation error details' do
      forecast = Forecast.new
      forecast.validate # Force validation to populate errors
      
      expect(Rails.logger).to receive(:error)
      
      ErrorHandlingService.handle_validation_error(forecast, context)
    end
  end
end
