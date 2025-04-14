# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForecastDetailsComponent, type: :component do
  let(:forecast) do
    instance_double('Forecast',
      id: 1,
      queried_at: Time.new(2025, 4, 10, 12, 0, 0),
      cache_expires_at: Time.new(2025, 4, 10, 12, 30, 0),
      timezone: 'America/Los_Angeles'
    )
  end
  
  let(:units) { 'metric' }
  
  it "renders the technical details section" do
    render_inline(ForecastDetailsComponent.new(forecast: forecast, units: units))
    
    expect(page).to have_content("Technical Details")
    expect(page).to have_content("Data Details")
    expect(page).to have_content("Forecast ID:")
    expect(page).to have_content("Retrieved:")
    expect(page).to have_content("Cache Expires:")
    expect(page).to have_content("Display Units:")
    expect(page).to have_content("Timezone:")
  end
  
  it "displays the correct forecast information" do
    render_inline(ForecastDetailsComponent.new(forecast: forecast, units: units))
    
    expect(page).to have_content("1") # ID
    expect(page).to have_content("2025-04-10 12:00:00") # queried_at
    expect(page).to have_content("2025-04-10 12:30:00") # cache_expires_at
    expect(page).to have_content("metric") # units
    expect(page).to have_content("America/Los_Angeles") # timezone
  end
  
  it "contains a toggle controller for collapsible behavior" do
    render_inline(ForecastDetailsComponent.new(forecast: forecast, units: units))
    
    expect(page).to have_css("[data-controller='toggle']")
    expect(page).to have_css("[data-action='toggle#toggle']")
    expect(page).to have_css("[data-toggle-target='trigger']")
    expect(page).to have_css("[data-toggle-target='content']")
    expect(page).to have_css("[data-toggle-target='icon']")
  end
  
  it "has proper accessibility attributes" do
    render_inline(ForecastDetailsComponent.new(forecast: forecast, units: units))
    
    expect(page).to have_css("button[aria-expanded='false']")
    expect(page).to have_css("button[aria-controls='technical-details']")
    expect(page).to have_css("div#technical-details")
  end
end
