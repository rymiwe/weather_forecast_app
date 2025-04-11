#!/usr/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)
require 'fileutils'

puts "Starting screenshot capture..."

# Create directories for screenshots if they don't exist
tmp_screenshots = Rails.root.join('tmp', 'screenshots').to_s
screenshots_dir = Rails.root.join('public', 'screenshots')
FileUtils.mkdir_p(screenshots_dir) unless Dir.exist?(screenshots_dir)
FileUtils.mkdir_p(tmp_screenshots) unless Dir.exist?(tmp_screenshots)

# Clean up existing screenshots to avoid confusion with stale images
puts "Cleaning up existing screenshots..."
FileUtils.rm_f(Dir.glob("#{tmp_screenshots}/*.png"))
FileUtils.rm_f(Dir.glob("#{screenshots_dir}/*.png"))

# Run the screenshot spec
puts "Running screenshot_helper_spec.rb..."
system("RAILS_ENV=test bundle exec rspec spec/system/screenshot_helper_spec.rb")

# Copy the screenshots from tmp to public so they can be accessed via browser
puts "Copying screenshots to public directory..."
if Dir.exist?(tmp_screenshots) && !Dir.glob("#{tmp_screenshots}/*.png").empty?
  # Copy all png files from tmp/screenshots to public/screenshots
  FileUtils.cp Dir.glob("#{tmp_screenshots}/*.png"), screenshots_dir
  
  # Create an index.html to easily view screenshots
  index_path = File.join(screenshots_dir, 'index.html')
  File.open(index_path, 'w') do |file|
    file.puts("<html>")
    file.puts("<head><title>Weather App Screenshots</title>")
    file.puts("<style>")
    file.puts("body { font-family: Arial, sans-serif; margin: 20px; background: #f7f7f7; }")
    file.puts("h1 { color: #333; text-align: center; margin-bottom: 30px; }")
    file.puts("img { max-width: 100%; height: auto; border: 1px solid #ddd; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }")
    file.puts(".screenshot { margin-bottom: 40px; background: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }")
    file.puts("h2 { color: #2c3e50; border-bottom: 1px solid #eee; padding-bottom: 10px; }")
    file.puts(".gallery { display: flex; flex-wrap: wrap; gap: 20px; justify-content: center; }")
    file.puts(".gallery a { display: block; width: 100%; text-decoration: none; color: inherit; }")
    file.puts(".gallery a:hover { opacity: 0.9; }")
    file.puts(".timestamp { color: #666; font-size: 0.8em; text-align: center; margin-top: 5px; }")
    file.puts("</style>")
    file.puts("</head>")
    file.puts("<body>")
    file.puts("<h1>Weather Forecast App Screenshots</h1>")
    file.puts("<div class='gallery'>")
    
    # Add each screenshot
    Dir.glob("#{screenshots_dir}/*.png").sort.each do |img|
      filename = File.basename(img)
      name = filename.sub('.png', '').sub(/^\d+_/, '').gsub('_', ' ').capitalize
      
      file.puts("<a href='#{filename}' target='_blank'>")
      file.puts("<div class='screenshot'>")
      file.puts("<h2>#{name}</h2>")
      file.puts("<img src='#{filename}' alt='#{name}'>")
      file.puts("<p class='timestamp'>Generated: #{Time.now.strftime('%Y-%m-%d %H:%M')}</p>")
      file.puts("</div>")
      file.puts("</a>")
    end
    
    file.puts("</div>")
    file.puts("</body>")
    file.puts("</html>")
  end
  
  puts "Screenshot gallery created at: /screenshots/index.html"
  puts "You can view it at: http://localhost:3000/screenshots/index.html"
else
  puts "No screenshots found in tmp/screenshots directory."
end
