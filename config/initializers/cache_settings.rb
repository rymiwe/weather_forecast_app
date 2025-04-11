# Set default cache configuration if not already defined
# This ensures consistent default behavior for cache durations

# Default cache duration is 30 minutes
Rails.configuration.x.weather.cache_duration ||= 30.minutes
