# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecentForecastsComponent, type: :component do
  let(:forecast1) do
    instance_double('Forecast',
      id: 1,
      address: 'Seattle, WA',
      current_temp: 18.5,
      display_units: 'metric',
      conditions: 'sunny',
      queried_at: 1.hour.ago
    )
  end
  
  let(:forecast2) do
    instance_double('Forecast',
      id: 2,
      address: 'Portland, OR',
      current_temp: 15.0,
      display_units: 'metric',
      conditions: 'rainy',
      queried_at: 30.minutes.ago
    )
  end
  
  let(:forecasts) { [forecast1, forecast2] }
  
  before do
    allow(forecast1).to receive(:to_key).and_return([1])
    allow(forecast2).to receive(:to_key).and_return([2])
    allow_any_instance_of(RecentForecastsComponent).to receive(:dom_id).with(forecast1).and_return("forecast_1")
    allow_any_instance_of(RecentForecastsComponent).to receive(:dom_id).with(forecast2).and_return("forecast_2")
    allow_any_instance_of(RecentForecastsComponent).to receive(:forecast_path).and_return("/forecasts/1")
    allow_any_instance_of(RecentForecastsComponent).to receive(:display_temperature).and_return("18°C")
    allow_any_instance_of(RecentForecastsComponent).to receive(:time_ago_in_words).and_return("1 hour")
  end
  
  it "renders nothing when no forecasts are present" do
    render_inline(RecentForecastsComponent.new(forecasts: []))
    
    expect(page).not_to have_css('section[aria-labelledby="recent-forecasts-heading"]')
    expect(page).not_to have_content('Recent Forecasts')
  end
  
  it "renders the section with forecasts when present" do
    render_inline(RecentForecastsComponent.new(forecasts: forecasts))
    
    expect(page).to have_css('section[aria-labelledby="recent-forecasts-heading"]')
    expect(page).to have_css('h2#recent-forecasts-heading', text: 'Recent Forecasts')
    expect(page).to have_css('.grid')
  end
  
  it "renders forecast cards for each forecast" do
    render_inline(RecentForecastsComponent.new(forecasts: forecasts))
    
    expect(page).to have_css('turbo-frame#forecast_1_card')
    expect(page).to have_css('turbo-frame#forecast_2_card')
    expect(page).to have_content('Seattle, WA')
    expect(page).to have_content('Portland, OR')
  end
  
  it "has a responsive grid layout" do
    render_inline(RecentForecastsComponent.new(forecasts: forecasts))
    
    expect(page).to have_css('.grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-3')
  end
end
