# frozen_string_literal: true

# Service for centralized error handling and logging
# Follows enterprise best practices by standardizing error responses
class ErrorHandler
  # Custom error classes for domain-specific errors
  class ApiError < StandardError; end
  class RateLimitError < StandardError; end
  class ConfigurationError < StandardError; end
  class ValidationError < StandardError; end
  
  # Handle errors for API services
  # @param error [Exception] The caught exception
  # @param context [Hash] Additional context for logging
  # @return [Hash] Standardized error response with consistent format
  def self.handle_api_error(error, context = {})
    log_error(error, context)
    
    case error
    when RateLimitError
      { error: 'Rate limit exceeded. Please try again later.', status: :too_many_requests }
    when ConfigurationError
      { error: 'Service configuration error. Please contact support.', status: :service_unavailable }
    when ApiError
      { error: 'API service error. Please try again later.', status: :bad_gateway }
    when JSON::ParserError
      { error: 'Invalid response format from external service.', status: :unprocessable_entity }
    when Net::HTTPError, Timeout::Error, Errno::ECONNREFUSED
      { error: 'Unable to connect to external service.', status: :service_unavailable }
    else
      { error: 'An unexpected error occurred.', status: :internal_server_error }
    end
  end
  
  # Handle validation errors
  # @param record [ActiveRecord::Base] The record with validation errors
  # @param context [Hash] Additional context for logging
  # @return [Hash] Standardized error response for validation errors
  def self.handle_validation_error(record, context = {})
    return { error: 'Invalid data provided.', status: :unprocessable_entity } unless record.respond_to?(:errors)
    
    error_messages = record.errors.full_messages.join(', ')
    log_validation_error(record, context)
    
    { error: error_messages, status: :unprocessable_entity }
  end
  
  # Log a detailed error with context
  # @param error [Exception] The exception to log
  # @param context [Hash] Additional context information
  # @return [void]
  def self.log_error(error, context = {})
    Rails.logger.error do
      {
        error_class: error.class.name,
        error_message: error.message,
        backtrace: error.backtrace&.first(5),
        context: context
      }.to_json
    end
  end
  
  # Log validation errors with context
  # @param record [ActiveRecord::Base] The record with validation errors
  # @param context [Hash] Additional context information
  # @return [void]
  def self.log_validation_error(record, context = {})
    Rails.logger.error do
      {
        record_class: record.class.name,
        record_errors: record.errors.to_hash,
        record_attributes: record.attributes.except('created_at', 'updated_at'),
        context: context
      }.to_json
    end
  end
end
