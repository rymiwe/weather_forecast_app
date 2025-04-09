# frozen_string_literal: true

# Helper for standardized date and time formatting
# Enterprise best practice to centralize formatting concerns
module DateTimeFormatterHelper
  # Format datetime for forecast headers
  # @param datetime [DateTime, Time] The datetime to format
  # @return [String] Formatted datetime string like "Wednesday, April 09, 2025 at 02:40 AM"
  def format_full_datetime(datetime)
    return "" unless datetime
    datetime.strftime("%A, %B %d, %Y at %I:%M %p")
  end
  
  # Format short date for forecast displays
  # @param date [Date, DateTime, Time] The date to format
  # @return [String] Formatted date string like "2025-04-09"
  def format_forecast_date(date)
    return "" unless date
    date.respond_to?(:strftime) ? date.strftime("%Y-%m-%d") : date.to_s
  end
  
  # Format day name for extended forecast
  # @param date [Date, DateTime, Time, String] The date to format or parse
  # @return [String] Day name like "Wednesday"
  def format_day_name(date)
    return "" unless date
    
    # Parse string dates
    if date.is_a?(String)
      begin
        date = Date.parse(date)
      rescue Date::Error
        return date # Return original if can't parse
      end
    end
    
    date.respond_to?(:strftime) ? date.strftime("%A") : date.to_s
  end
  
  # Format time for caching information
  # @param time [Time, DateTime] The time to format
  # @return [String] Formatted time like "03:10 AM"
  def format_cache_time(time)
    return "" unless time
    time.strftime("%I:%M %p")
  end
end
