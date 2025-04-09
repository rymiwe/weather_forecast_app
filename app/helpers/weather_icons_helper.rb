# frozen_string_literal: true

# Helper to provide weather condition icons
module WeatherIconsHelper
  # Return an appropriate SVG icon for the given weather condition
  # @param condition [String] Weather condition text
  # @param classes [String] Additional CSS classes for the SVG
  # @return [String] SVG icon HTML
  def weather_icon(condition, classes = "h-8 w-8")
    condition = condition.to_s.downcase
    
    icon_html = case condition
    when /sunny|clear/
      sunny_icon(classes)
    when /cloud|overcast/
      cloudy_icon(classes)
    when /rain|shower|drizzle/
      rainy_icon(classes)
    when /storm|thunder/
      storm_icon(classes)
    when /snow|sleet|hail/
      snow_icon(classes)
    when /fog|mist|haze/
      fog_icon(classes)
    when /wind/
      windy_icon(classes)
    else
      # Default icon if condition doesn't match
      partly_cloudy_icon(classes)
    end
    
    # Mark as HTML safe since we're returning SVG code
    icon_html.html_safe
  end
  
  private
  
  def sunny_icon(classes)
    <<-SVG
    <svg xmlns="http://www.w3.org/2000/svg" class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="12" cy="12" r="5" fill="#FFD700" stroke="#F59E0B"></circle>
      <line x1="12" y1="1" x2="12" y2="3"></line>
      <line x1="12" y1="21" x2="12" y2="23"></line>
      <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
      <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
      <line x1="1" y1="12" x2="3" y2="12"></line>
      <line x1="21" y1="12" x2="23" y2="12"></line>
      <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
      <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
    </svg>
    SVG
  end
  
  def cloudy_icon(classes)
    <<-SVG
    <svg xmlns="http://www.w3.org/2000/svg" class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" fill="#D1D5DB"></path>
    </svg>
    SVG
  end
  
  def rainy_icon(classes)
    <<-SVG
    <svg xmlns="http://www.w3.org/2000/svg" class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" fill="#D1D5DB"></path>
      <line x1="8" y1="19" x2="8" y2="21" stroke="#3B82F6"></line>
      <line x1="12" y1="19" x2="12" y2="21" stroke="#3B82F6"></line>
      <line x1="16" y1="19" x2="16" y2="21" stroke="#3B82F6"></line>
    </svg>
    SVG
  end
  
  def storm_icon(classes)
    <<-SVG
    <svg xmlns="http://www.w3.org/2000/svg" class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" fill="#D1D5DB"></path>
      <line x1="12" y1="10" x2="12.01" y2="20" stroke="#FBBF24"></line>
      <polyline points="9 13 12 10 15 13" stroke="#FBBF24" fill="#FBBF24"></polyline>
    </svg>
    SVG
  end
  
  def snow_icon(classes)
    <<-SVG
    <svg xmlns="http://www.w3.org/2000/svg" class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" fill="#D1D5DB"></path>
      <circle cx="8" cy="20" r="1" fill="#E5E7EB"></circle>
      <circle cx="12" cy="20" r="1" fill="#E5E7EB"></circle>
      <circle cx="16" cy="20" r="1" fill="#E5E7EB"></circle>
    </svg>
    SVG
  end
  
  def fog_icon(classes)
    <<-SVG
    <svg xmlns="http://www.w3.org/2000/svg" class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <line x1="5" y1="5" x2="19" y2="5" stroke="#9CA3AF"></line>
      <line x1="3" y1="9" x2="21" y2="9" stroke="#9CA3AF"></line>
      <line x1="5" y1="13" x2="19" y2="13" stroke="#9CA3AF"></line>
      <line x1="3" y1="17" x2="21" y2="17" stroke="#9CA3AF"></line>
    </svg>
    SVG
  end
  
  def windy_icon(classes)
    <<-SVG
    <svg xmlns="http://www.w3.org/2000/svg" class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M9.59 4.59A2 2 0 1 1 11 8H2m10.59 11.41A2 2 0 1 0 14 16H2m15.73-8.27A2.5 2.5 0 1 1 19.5 12H2" stroke="#6B7280"></path>
    </svg>
    SVG
  end
  
  def partly_cloudy_icon(classes)
    <<-SVG
    <svg xmlns="http://www.w3.org/2000/svg" class="#{classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M18 10h-1.26a8 8 0 1 0-11.62-9"></path>
      <circle cx="7" cy="6" r="3" fill="#FFD700" stroke="#F59E0B"></circle>
      <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" fill="#D1D5DB"></path>
    </svg>
    SVG
  end
end
