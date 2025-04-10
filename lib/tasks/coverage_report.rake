namespace :coverage do
  desc "Print coverage report sorted by coverage percentage"
  task :report => :environment do
    require 'json'
    require 'terminal-table'

    resultset_path = "coverage/.resultset.json"
    if File.exist?(resultset_path)
      data = JSON.parse(File.read(resultset_path))
      rspec = data["RSpec"]
      coverage = rspec["coverage"]
      
      results = []
      coverage.each do |file_path, coverage_data|
        # Skip non-app files and files without code
        next unless file_path.start_with?("#{Rails.root}/app/")
        
        # Calculate coverage from the coverage_data array
        lines = coverage_data
        next if lines.nil? || lines.empty?
        
        covered = lines.count { |line| line.is_a?(Integer) && line > 0 }
        total = lines.count { |line| line.is_a?(Integer) || line.nil? }
        percentage = total > 0 ? (covered.to_f / total * 100).round(2) : 100.0
        
        results << [file_path.gsub("#{Rails.root}/", ''), "#{percentage}%", "#{covered}/#{total}"]
      end
      
      # Sort by coverage percentage (ascending)
      results.sort_by! { |row| row[1].to_f }
      
      # Create table
      table = Terminal::Table.new(
        title: "Code Coverage Report",
        headings: ['File', 'Coverage %', 'Lines'],
        rows: results
      )
      
      puts table
      
      # Calculate overall coverage
      total_covered = results.sum { |_, perc, lines| lines.split('/')[0].to_i }
      total_lines = results.sum { |_, perc, lines| lines.split('/')[1].to_i }
      overall = (total_covered.to_f / total_lines * 100).round(2)
      
      puts "\nOverall Coverage: #{overall}% (#{total_covered}/#{total_lines} lines)"
      
      # List of files below 90% coverage
      low_coverage = results.select { |r| r[1].to_f < 90 }
      if low_coverage.any?
        puts "\nFiles below 90% coverage:"
        low_coverage.each do |file, percentage, lines|
          puts "  #{file}: #{percentage} (#{lines})"
        end
      end
    else
      puts "No coverage data found. Run your tests with SimpleCov first."
    end
  end
end
