# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"  # Updated to a version supported on Heroku-24 stack

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5", ">= 7.1.5.1"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use sqlite3 as the database for Active Record in development and test
group :development, :test do
  gem "sqlite3", "~> 1.4"
end

# Use PostgreSQL in production for Heroku compatibility
group :production do
  gem 'pg'
end

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use ViewComponent for component-based UI architecture
# gem "view_component"

# Geocoder for address parsing and geocoding
gem 'geocoder'

# HTTP client for API requests
gem 'faraday'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mswin mingw x64_mingw ]
  
  # RSpec for testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "rails-controller-testing" # For asserting template and request assignments
  gem 'simplecov', require: false
  gem 'terminal-table', require: false
  
  # VCR for recording HTTP interactions in tests
  gem 'vcr'
  gem 'webmock'
end

group :test do
  # For database cleaning in tests
  gem 'database_cleaner-active_record'
  
  # Use Capybara for system testing
  gem "capybara"
  gem "selenium-webdriver", "~> 4.10.0" # Specify compatible version for webdrivers
  gem "webdrivers", "~> 5.3.0" # For auto-installing drivers like Chrome, Firefox, etc.
  gem "launchy"                # For debugging with save_and_open_page
  # Percy for visual testing - use specific version to avoid dependency conflicts
  gem 'percy-capybara', '~> 4.3.2'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Ruby linting and code style checking
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end
