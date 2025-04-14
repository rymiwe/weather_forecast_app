# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherCardComponent, type: :component do
  let(:forecast) { double('Forecast', 
    address: 'Seattle, WA', 
    conditions: 'cloudy', 
    current_temp: 15.5,
    display_units: 'metric'
  ) }
  
  describe "with forecast data" do
    it "renders temperature correctly" do
      render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric'))
      expect(page).to have_content('15.5°C')
    end
    
    it "renders conditions correctly" do
      render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric'))
      expect(page).to have_content('Cloudy')
    end
    
    it "renders current date correctly" do
      allow(Time).to receive(:current).and_return(Time.new(2024, 4, 10))
      render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric'))
      expect(page).to have_content('Wednesday, Apr 10')
    end
    
    it "converts temperature to imperial when specified" do
      render_inline(WeatherCardComponent.new(forecast: forecast, units: 'imperial'))
      # 15.5°C is about 60°F
      expect(page).to have_content('60°F')
    end
  end
  
  describe "with day_data" do
    let(:day_data) { {
      'date' => '2024-04-11',
      'conditions' => 'sunny',
      'high' => 22.0,
      'low' => 15.0
    } }
    
    it "renders day-specific date" do
      render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric', day_data: day_data))
      expect(page).to have_content('Thursday, Apr 11')
    end
    
    it "renders day-specific temperature" do
      render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric', day_data: day_data))
      expect(page).to have_content('22°C')
    end
    
    it "renders day-specific conditions" do
      render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric', day_data: day_data))
      expect(page).to have_content('Sunny')
    end
    
    it "includes low temperature" do
      render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric', day_data: day_data))
      expect(page).to have_content('Low: 15°C')
    end
  end
  
  it "correctly uses the WeatherIconComponent" do
    render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric'))
    # The component itself should render a weather icon component
    expect(page).to have_selector('.mt-4.text-center')
  end
  
  it "includes accessibility description" do
    render_inline(WeatherCardComponent.new(forecast: forecast, units: 'metric'))
    expect(page).to have_css('.sr-only', text: /Weather for .* with temperature/)
  end
end
