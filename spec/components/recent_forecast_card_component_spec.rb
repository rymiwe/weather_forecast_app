# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecentForecastCardComponent, type: :component do
  let(:forecast) do
    instance_double('Forecast',
      id: 1,
      address: 'Seattle, WA',
      current_temp: 18.5,
      display_units: 'metric',
      conditions: 'sunny',
      queried_at: 1.hour.ago
    )
  end
  
  before do
    allow(forecast).to receive(:to_key).and_return([1])
    allow_any_instance_of(RecentForecastCardComponent).to receive(:dom_id).with(forecast).and_return("forecast_1")
    allow_any_instance_of(RecentForecastCardComponent).to receive(:forecast_path).and_return("/forecasts/1")
    allow_any_instance_of(RecentForecastCardComponent).to receive(:display_temperature).and_return("18°C")
    allow_any_instance_of(RecentForecastCardComponent).to receive(:time_ago_in_words).and_return("1 hour")
    allow_any_instance_of(WeatherIconComponent).to receive(:render_in).and_return("<div>Weather Icon</div>")
  end
  
  it "renders a forecast card with correct structure" do
    render_inline(RecentForecastCardComponent.new(forecast: forecast))
    
    expect(page).to have_css('turbo-frame#forecast_1_card')
    expect(page).to have_css('a[href="/forecasts/1"]')
    expect(page).to have_css('.rounded-lg.shadow-md')
    expect(page).to have_css('h3', text: 'Seattle, WA')
    expect(page).to have_content('18°C')
    expect(page).to have_content('Sunny')
    expect(page).to have_content('1 hour ago')
  end
  
  it "applies appropriate background class based on weather conditions" do
    component = RecentForecastCardComponent.new(forecast: forecast)
    allow(component).to receive(:forecast_card_background_class).and_return("bg-yellow-100")
    
    render_inline(component)
    
    expect(page).to have_css('.bg-yellow-100')
  end
  
  it "calls forecast_card_background_class with correct parameters" do
    component = RecentForecastCardComponent.new(forecast: forecast)
    
    expect(component).to receive(:forecast_card_background_class)
      .with('sunny', 18.5, 'metric')
      .and_return('bg-yellow-100')
    
    render_inline(component)
  end
  
  it "displays the weather icon" do
    expect(WeatherIconComponent).to receive(:new)
      .with(condition: 'sunny', size: :small)
      .and_call_original
    
    render_inline(RecentForecastCardComponent.new(forecast: forecast))
  end
  
  it "has hover scale effect for better UX" do
    render_inline(RecentForecastCardComponent.new(forecast: forecast))
    
    expect(page).to have_css('.transition-transform.hover\\:scale-105')
  end
end
