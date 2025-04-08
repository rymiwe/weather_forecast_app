# Load environment variables from a YAML file
# This is a simple approach for development; in production, use proper environment variables

env_file = Rails.root.join('config', 'env.yml')

if File.exist?(env_file)
  env_vars = YAML.load_file(env_file)
  
  env_vars.each do |key, value|
    ENV[key.to_s] = value.to_s
  end
  
  Rails.logger.info "Loaded environment variables from config/env.yml"
else
  Rails.logger.warn "No config/env.yml found. Some features may not work without required API keys."
end
