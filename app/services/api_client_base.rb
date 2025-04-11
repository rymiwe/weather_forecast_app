# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'

# Base class for all API clients with common error handling and request methods
# This is the primary API client base implementation for the application
class ApiClientBase
  # Custom errors
  class ApiError < StandardError
    attr_reader :status, :code, :response
    
    def initialize(message, status: nil, code: nil, response: nil)
      @status = status
      @code = code
      @response = response
      super(message)
    end
  end
  
  class RateLimitExceededError < ApiError; end
  class ConfigurationError < ApiError; end
  class AuthenticationError < ApiError; end
  class TimeoutError < ApiError; end
  
  attr_reader :api_key, :base_url, :logger
  
  # Initialize with API key and base URL
  # @param api_key [String] API key for authentication
  # @param base_url [String] Base URL for API requests
  # @param timeout [Integer] Request timeout in seconds
  def initialize(api_key: nil, base_url: nil, timeout: 15)
    @api_key = api_key
    @base_url = base_url
    @logger = Rails.logger
    @timeout = timeout
    
    validate_configuration if api_key.present? || base_url.present?
  end
  
  # Perform a GET request to the API
  # @param endpoint [String] API endpoint to call
  # @param params [Hash] Query parameters
  # @param headers [Hash] HTTP headers
  # @return [Hash] Parsed JSON response
  def get(endpoint, params: {}, headers: {})
    perform_request(:get, endpoint, params: params, headers: headers)
  end
  
  # Perform a POST request to the API
  # @param endpoint [String] API endpoint to call
  # @param body [Hash] Request body
  # @param headers [Hash] HTTP headers
  # @return [Hash] Parsed JSON response
  def post(endpoint, body: {}, headers: {})
    perform_request(:post, endpoint, body: body, headers: headers)
  end
  
  # Make a direct GET request to a URL (not using base_url)
  # @param url [String] Full URL to request
  # @param params [Hash] Query parameters
  # @param headers [Hash] HTTP headers
  # @return [Hash] Parsed JSON response
  def get_url(url, params: {}, headers: {})
    begin
      logger.info("API Direct Request: GET #{url}")
      uri = URI(url)
      
      # Add query parameters if provided
      if params.present?
        query_params = URI.encode_www_form(params)
        uri.query = uri.query.present? ? "#{uri.query}&#{query_params}" : query_params
      end
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      
      request = Net::HTTP::Get.new(uri)
      headers.each { |key, value| request[key] = value }
      
      response = http.request(request)
      handle_response(response)
    rescue Net::ReadTimeout, Timeout::Error => e
      logger.error("API Timeout Error: #{e.message}")
      raise TimeoutError.new("Request timed out after #{@timeout} seconds", status: 408)
    rescue => e
      logger.error("API Request Error: #{e.message}")
      raise ApiError.new("Request failed: #{e.message}")
    end
  end
  
  private
  
  # Validate API configuration before making requests
  def validate_configuration
    raise ConfigurationError, "Missing API key" if api_key.blank?
    raise ConfigurationError, "Missing base URL" if base_url.blank?
  end
  
  # Perform an HTTP request and handle errors
  # @param method [Symbol] HTTP method
  # @param endpoint [String] API endpoint
  # @param options [Hash] Request options
  # @return [Hash] Parsed JSON response
  def perform_request(method, endpoint, **options)
    url = "#{base_url}/#{endpoint.gsub(/^\//, '')}"
    uri = URI(url)
    
    begin
      logger.info("API Request: #{method.upcase} #{url}")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      
      case method
      when :get
        # Add query parameters if provided
        if options[:params].present?
          query_params = URI.encode_www_form(options[:params])
          uri.query = uri.query.present? ? "#{uri.query}&#{query_params}" : query_params
        end
        
        request = Net::HTTP::Get.new(uri)
      when :post
        request = Net::HTTP::Post.new(uri)
        request.body = options[:body].to_json if options[:body].present?
        request.content_type = 'application/json'
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end
      
      # Add headers
      options[:headers].each { |key, value| request[key] = value } if options[:headers].present?
      
      response = http.request(request)
      handle_response(response)
    rescue Net::ReadTimeout, Timeout::Error => e
      logger.error("API Timeout Error: #{e.message}")
      raise TimeoutError.new("Request timed out after #{@timeout} seconds", status: 408)
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET => e
      logger.error("API Connection Error: #{e.message}")
      raise ApiError.new("Unable to connect to API: #{e.message}", status: 503)
    rescue => e
      logger.error("API Unknown Error: #{e.message}")
      raise ApiError.new("Request failed: #{e.message}")
    end
  end
  
  # Handle API response and raise appropriate errors
  # @param response [Net::HTTPResponse] API response
  # @return [Hash] Parsed JSON response
  def handle_response(response)
    case response.code.to_i
    when 200..299
      parse_response(response)
    when 401, 403
      logger.error("API Authentication Error: #{response.code}")
      raise AuthenticationError.new(
        "Authentication failed", 
        status: response.code.to_i,
        response: safe_parse_json(response.body)
      )
    when 429
      logger.error("API Rate Limit Exceeded: #{response.code}")
      raise RateLimitExceededError.new(
        "Rate limit exceeded", 
        status: response.code.to_i,
        response: safe_parse_json(response.body)
      )
    when 400..499
      logger.error("API Client Error: #{response.code} - #{response.body}")
      error_data = safe_parse_json(response.body)
      error_msg = error_data["message"] || "Client error"
      
      raise ApiError.new(
        "API Error: #{error_msg}",
        status: response.code.to_i,
        response: error_data
      )
    when 500..599
      logger.error("API Server Error: #{response.code} - #{response.body}")
      raise ApiError.new(
        "API server error", 
        status: response.code.to_i,
        response: safe_parse_json(response.body)
      )
    else
      logger.error("API Unknown Error: #{response.code} - #{response.body}")
      raise ApiError.new(
        "Unknown error", 
        status: response.code.to_i,
        response: safe_parse_json(response.body)
      )
    end
  end
  
  # Parse JSON response and handle parsing errors
  # @param response [Net::HTTPResponse] API response
  # @return [Hash] Parsed JSON
  def parse_response(response)
    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      logger.error("API Response Parse Error: #{e.message}")
      raise ApiError.new(
        "Invalid response format: #{e.message}",
        status: response.code.to_i,
        response: response.body
      )
    end
  end
  
  # Safely parse JSON without raising errors
  # @param body [String] JSON string to parse
  # @return [Hash] Parsed JSON or empty hash
  def safe_parse_json(body)
    return {} if body.blank?
    
    begin
      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end
  end
end
