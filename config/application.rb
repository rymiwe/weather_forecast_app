require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WeatherForecastApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `config.assets.precompile` list all the assets that will be compiled.
    config.assets.paths << Rails.root.join("node_modules")
    
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Weather app configuration
    config.x.weather = ActiveSupport::InheritableOptions.new
    
    # Cache duration for weather data
    config.x.weather.cache_duration_minutes = ENV.fetch('WEATHER_CACHE_DURATION_MINUTES', 30).to_i
    config.x.weather.cache_ttl = config.x.weather.cache_duration_minutes.minutes
    
    # Always store weather data in metric units for consistency
    config.x.weather.storage_unit = 'metric'
    
    # Number of days to display in forecast
    config.x.weather.forecast_days = 5
    
    # Whether to use the mock client (default to false if not set)
    config.x.weather.use_mock_client = ENV.fetch('USE_MOCK_WEATHER_CLIENT', 'false').downcase == 'true'

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    # Load environment variables from env.yml file
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'env.yml')
      if File.exist?(env_file)
        YAML.load(File.open(env_file)).each do |key, value|
          ENV[key.to_s] = value.to_s
        end
        # Remove Rails.logger.debug call as it's not available at this point
      end
    end
  end
end
