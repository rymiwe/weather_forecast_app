# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExtendedForecastComponent, type: :component do
  let(:forecast) do
    instance_double('Forecast',
      address: 'Seattle, WA',
      conditions: 'cloudy',
      current_temp: 15.5,
      display_units: 'metric'
    )
  end
  
  let(:forecast_data) do
    [
      { 'date' => '2025-04-11', 'conditions' => 'sunny', 'high' => 18.0, 'low' => 10.0 },
      { 'date' => '2025-04-12', 'conditions' => 'rainy', 'high' => 16.0, 'low' => 8.0 }
    ]
  end
  
  let(:units) { 'metric' }
  
  before do
    allow(forecast).to receive(:extended_forecast_data).and_return(forecast_data)
  end
  
  it "renders the extended forecast section" do
    # Mock the WeatherCardComponent rendering
    allow_any_instance_of(WeatherCardComponent).to receive(:render_in).and_return("<div>Weather Card</div>")
    
    render_inline(ExtendedForecastComponent.new(forecast: forecast, units: units))
    
    expect(page).to have_content("5-Day Forecast")
    expect(page).to have_css('section[aria-labelledby="extended-forecast-heading"]')
    expect(page).to have_css('h2#extended-forecast-heading')
  end
  
  it "renders weather cards for each forecast day" do
    # Test that the component renders WeatherCardComponent for each day
    expect(WeatherCardComponent).to receive(:new).exactly(2).times.and_call_original
    allow_any_instance_of(WeatherCardComponent).to receive(:render_in).and_return("<div>Weather Card</div>")
    
    render_inline(ExtendedForecastComponent.new(forecast: forecast, units: units))
  end
  
  it "uses the first 5 days of forecast data" do
    # Test the forecast_days method
    component = ExtendedForecastComponent.new(forecast: forecast, units: units)
    expect(component.forecast_days).to eq(forecast_data)
  end
  
  it "has a responsive grid layout" do
    allow_any_instance_of(WeatherCardComponent).to receive(:render_in).and_return("<div>Weather Card</div>")
    
    render_inline(ExtendedForecastComponent.new(forecast: forecast, units: units))
    
    expect(page).to have_css('.grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-5')
  end
end
