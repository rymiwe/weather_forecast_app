# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForecastHeaderComponent, type: :component do
  let(:forecast) do
    instance_double('Forecast',
      id: 1,
      address: 'Seattle, WA',
      cached?: true,
      queried_at: Time.new(2025, 4, 10, 12, 0, 0)
    )
  end
  
  it "renders the forecast header with location" do
    # Mock the CachedDataBadgeComponent rendering
    allow_any_instance_of(CachedDataBadgeComponent).to receive(:render_in).and_return("<div>Cached Data Badge</div>")
    
    render_inline(ForecastHeaderComponent.new(forecast: forecast))
    
    expect(page).to have_content("Weather for Seattle, WA")
    expect(page).to have_css('header')
    expect(page).to have_css('h1')
  end
  
  it "includes a dom_id for the forecast title" do
    allow_any_instance_of(CachedDataBadgeComponent).to receive(:render_in).and_return("<div>Cached Data Badge</div>")
    allow_any_instance_of(ForecastHeaderComponent).to receive(:dom_id).with(forecast).and_return("forecast_1")
    
    render_inline(ForecastHeaderComponent.new(forecast: forecast))
    
    expect(page).to have_css('h1#forecast_1_title')
  end
  
  it "renders the CachedDataBadgeComponent" do
    # Test that the component renders the CachedDataBadgeComponent
    expect(CachedDataBadgeComponent).to receive(:new).with(forecast: forecast).and_call_original
    allow_any_instance_of(CachedDataBadgeComponent).to receive(:render_in).and_return("<div>Cached Data Badge</div>")
    
    render_inline(ForecastHeaderComponent.new(forecast: forecast))
  end
end
