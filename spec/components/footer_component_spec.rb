require 'rails_helper'

RSpec.describe FooterComponent, type: :component do
  before do
    # Freeze time for consistent testing
    allow(Time).to receive(:current).and_return(Time.new(2025))
  end
  
  it "renders the footer with default values" do
    render_inline(FooterComponent.new)
    
    expect(page).to have_css('footer.bg-gray-800')
    expect(page).to have_css('h2', text: 'Weather Forecast App')
    expect(page).to have_content('Powered by OpenWeatherMap API')
    expect(page).to have_content('© 2025 Weather Forecast App')
    expect(page).to have_content('All rights reserved')
  end
  
  it "renders the footer with custom app name" do
    render_inline(FooterComponent.new(app_name: "Custom App Name"))
    
    expect(page).to have_css('h2', text: 'Custom App Name')
    expect(page).to have_content('© 2025 Custom App Name')
  end
  
  it "renders the footer with custom powered by text" do
    render_inline(FooterComponent.new(powered_by: "Custom API"))
    
    expect(page).to have_content('Powered by Custom API')
  end
  
  it "has a responsive layout" do
    render_inline(FooterComponent.new)
    
    expect(page).to have_css('.flex-col.md\\:flex-row')
    expect(page).to have_css('.text-center.md\\:text-right')
  end
end
