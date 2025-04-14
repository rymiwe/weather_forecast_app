# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherIconComponent, type: :component do
  it "renders the correct icon for snow conditions" do
    render_inline(WeatherIconComponent.new(condition: "snow"))
    expect(page).to have_css("i.fas.fa-snowflake.text-blue-500")
    expect(page).to have_css(".sr-only", text: "snow")
  end
  
  it "renders the correct icon for rain conditions" do
    render_inline(WeatherIconComponent.new(condition: "rain"))
    expect(page).to have_css("i.fas.fa-cloud-rain.text-blue-700")
    expect(page).to have_css(".sr-only", text: "rain")
  end
  
  it "renders the correct icon for cloudy conditions" do
    render_inline(WeatherIconComponent.new(condition: "cloudy"))
    expect(page).to have_css("i.fas.fa-cloud.text-gray-500")
    expect(page).to have_css(".sr-only", text: "cloudy")
  end
  
  it "renders the correct icon for sunny conditions" do
    render_inline(WeatherIconComponent.new(condition: "sunny"))
    expect(page).to have_css("i.fas.fa-sun.text-yellow-500")
    expect(page).to have_css(".sr-only", text: "sunny")
  end
  
  it "renders the correct icon for foggy conditions" do
    render_inline(WeatherIconComponent.new(condition: "fog"))
    expect(page).to have_css("i.fas.fa-smog.text-gray-400")
    expect(page).to have_css(".sr-only", text: "fog")
  end
  
  it "renders the correct icon for thunderstorm conditions" do
    render_inline(WeatherIconComponent.new(condition: "thunderstorm"))
    expect(page).to have_css("i.fas.fa-bolt.text-purple-500")
    expect(page).to have_css(".sr-only", text: "thunderstorm")
  end
  
  it "renders the default icon for unknown conditions" do
    render_inline(WeatherIconComponent.new(condition: "unknown"))
    expect(page).to have_css("i.fas.fa-cloud-sun.text-gray-600")
    expect(page).to have_css(".sr-only", text: "unknown")
  end
  
  it "applies the correct size class based on size parameter" do
    render_inline(WeatherIconComponent.new(condition: "sunny", size: "sm"))
    expect(page).to have_css("i.text-2xl")
    
    render_inline(WeatherIconComponent.new(condition: "sunny", size: "md"))
    expect(page).to have_css("i.text-3xl")
    
    render_inline(WeatherIconComponent.new(condition: "sunny", size: "lg"))
    expect(page).to have_css("i.text-4xl")
    
    render_inline(WeatherIconComponent.new(condition: "sunny", size: "xl"))
    expect(page).to have_css("i.text-5xl")
  end
end
