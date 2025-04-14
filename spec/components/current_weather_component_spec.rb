# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurrentWeatherComponent, type: :component do
  let(:forecast) do
    instance_double('Forecast',
      address: 'Seattle, WA',
      conditions: 'cloudy',
      current_temp: 15.5,
      display_units: 'metric'
    )
  end
  
  let(:units) { 'metric' }
  
  it "renders the current weather section" do
    # We need to allow render_inline to be called on WeatherCardComponent
    allow_any_instance_of(WeatherCardComponent).to receive(:render_in).and_return("<div>Weather Card</div>")
    
    render_inline(CurrentWeatherComponent.new(forecast: forecast, units: units))
    
    expect(page).to have_content("Current Weather")
    expect(page).to have_css('section[aria-labelledby="current-weather-heading"]')
    expect(page).to have_css('h2#current-weather-heading')
  end
  
  it "includes the WeatherCardComponent" do
    # Test that the component renders the WeatherCardComponent
    expect(WeatherCardComponent).to receive(:new).with(forecast: forecast, units: units).and_call_original
    allow_any_instance_of(WeatherCardComponent).to receive(:render_in).and_return("<div>Weather Card</div>")
    
    render_inline(CurrentWeatherComponent.new(forecast: forecast, units: units))
  end
end
