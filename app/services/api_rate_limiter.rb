# frozen_string_literal: true

# Service to enforce rate limits for external API calls
class ApiRateLimiter
  # Redis connection would be ideal for production use
  # For this demo, we'll use a class variable with a mutex for thread safety
  @@request_counts = {}
  @@mutex = Mutex.new
  
  # Default maximum requests per minute for the free tier
  DEFAULT_MAX_REQUESTS_PER_MINUTE = 60
  
  # Check if a request is allowed under the current rate limit
  # Increments the request count if allowed
  #
  # @param service_name [String] name of the service being rate limited (e.g., 'openweathermap')
  # @return [Boolean] true if request is allowed, false if rate limited
  def self.allow_request?(service_name)
    max_requests = Rails.configuration.x.weather.max_requests_per_minute || DEFAULT_MAX_REQUESTS_PER_MINUTE
    current_minute = Time.current.strftime('%Y-%m-%d-%H-%M')
    key = "#{service_name}:#{current_minute}"
    
    @@mutex.synchronize do
      # Clear old entries (simple cleanup)
      cleanup_old_entries
      
      # Initialize counter if not exists
      @@request_counts[key] ||= 0
      
      # Check if under limit
      if @@request_counts[key] < max_requests
        # Increment and allow
        @@request_counts[key] += 1
        true
      else
        # Rate limit exceeded
        Rails.logger.warn("Rate limit exceeded for #{service_name}: #{max_requests} requests per minute")
        false
      end
    end
  end
  
  # Get the current request count for a service in the current minute
  #
  # @param service_name [String] name of the service
  # @return [Integer] current request count
  def self.current_request_count(service_name)
    current_minute = Time.current.strftime('%Y-%m-%d-%H-%M')
    key = "#{service_name}:#{current_minute}"
    
    @@mutex.synchronize do
      @@request_counts[key] || 0
    end
  end
  
  # For testing: reset all request counts
  def self.reset!
    @@mutex.synchronize do
      @@request_counts = {}
    end
  end
  
  private
  
  # Remove entries older than the current minute
  def self.cleanup_old_entries
    current_minute = Time.current.strftime('%Y-%m-%d-%H-%M')
    
    @@request_counts.keys.each do |key|
      @@request_counts.delete(key) unless key.end_with?(current_minute)
    end
  end
end
