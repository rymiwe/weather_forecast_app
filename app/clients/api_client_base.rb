# frozen_string_literal: true

require 'faraday'
require 'singleton'
require 'json'

# Base class for API clients, providing common functionality
class ApiClientBase
  include Singleton

  def initialize(api_key:, base_url:)
    @api_key = api_key
    @base_url = base_url
  end

  private

  attr_reader :api_key, :base_url

  # Perform an HTTP request using Faraday
  # @param method [Symbol] HTTP method
  # @param endpoint [String] API endpoint
  # @param params [Hash] Request parameters
  # @param headers [Hash] Request headers
  # @return [Hash] Parsed JSON response
  def request(endpoint, params = {}, headers = {})
    conn = Faraday.new(url: base_url) do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get(endpoint, params, headers)
    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    else
      raise "API request failed with status code #{response.status}"
    end
  end
end