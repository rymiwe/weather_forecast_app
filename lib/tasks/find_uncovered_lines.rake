namespace :coverage do
  desc "Find specific uncovered lines to target for testing"
  task :find_uncovered_lines => :environment do
    require 'json'
    
    results_file = "coverage/.resultset.json"
    if File.exist?(results_file)
      data = JSON.parse(File.read(results_file))
      coverage_data = data["RSpec"]["coverage"]
      
      puts "Files with uncovered lines:\n"
      puts "-" * 80
      
      total_uncovered = 0
      
      coverage_data.each do |file_path, lines|
        next unless file_path.include?('/app/')
        
        uncovered_lines = []
        lines.each_with_index do |coverage, index|
          # 0 means the line exists but is not covered by tests
          uncovered_lines << (index + 1) if coverage == 0
        end
        
        if uncovered_lines.any?
          relative_path = file_path.gsub("#{Rails.root}/", '')
          puts "\n#{relative_path} (#{uncovered_lines.size} uncovered lines)"
          puts "-" * 80
          
          # Group consecutive lines
          line_groups = []
          current_group = []
          
          uncovered_lines.each do |line|
            if current_group.empty? || line == current_group.last + 1
              current_group << line
            else
              line_groups << current_group
              current_group = [line]
            end
          end
          line_groups << current_group unless current_group.empty?
          
          # Print the line groups
          line_groups.each do |group|
            if group.size == 1
              puts "Line #{group.first}"
            else
              puts "Lines #{group.first}-#{group.last}"
            end
            
            # Show the actual code for these lines
            begin
              file_content = File.readlines(file_path)
              group.each do |line_num|
                puts "  #{line_num}: #{file_content[line_num-1].strip}"
              end
            rescue => e
              puts "  Could not read file content: #{e.message}"
            end
          end
          
          total_uncovered += uncovered_lines.size
        end
      end
      
      puts "\nTotal uncovered lines: #{total_uncovered}"
    else
      puts "No coverage data found. Run tests with coverage first."
    end
  end
end
