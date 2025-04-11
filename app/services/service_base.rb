# frozen_string_literal: true

# Base class for all service objects in the application
# Provides common functionality and enforces consistent patterns
module ServiceBase
  extend ActiveSupport::Concern

  # Class methods added to classes that include this module
  module ClassMethods
    # Call the service directly from the class
    # @param args [Hash] Arguments to pass to the service
    # @return [Object] Result of the service call
    def call(*args, **kwargs)
      new(*args, **kwargs).call
    end
  end

  # Instance methods for service objects
  included do
    # Always include the Rails logger
    include ActiveSupport::Configurable
    include ActiveSupport::Callbacks
    
    # Set up callbacks
    define_callbacks :call
    
    # Log all service calls by default
    set_callback :call, :around do |_service, block|
      start_time = Time.current
      Rails.logger.info("[#{self.class.name}] Started")
      
      begin
        result = block.call
        Rails.logger.info("[#{self.class.name}] Completed in #{Time.current - start_time}s")
        result
      rescue => e
        Rails.logger.error("[#{self.class.name}] Failed: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise
      end
    end
  end
  
  # Force subclasses to implement #call
  def call
    raise NotImplementedError, "#{self.class.name} must implement #call"
  end
  
  # Check if the service succeeded
  # @return [Boolean] True if the service succeeded
  def success?
    !failure?
  end
  
  # Check if the service failed
  # @return [Boolean] True if the service failed
  def failure?
    false
  end
end
