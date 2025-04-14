# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppHeaderComponent, type: :component do
  it "renders the header with default title and subtitle" do
    render_inline(AppHeaderComponent.new)
    
    expect(page).to have_css('h1', text: 'Weather Forecast App')
    expect(page).to have_css('p', 
                             text: 'Get accurate weather forecasts for any location worldwide with our simple weather application.')
  end
  
  it "renders the header with custom title and subtitle" do
    render_inline(AppHeaderComponent.new(
      title: "Custom Title", 
      subtitle: "Custom subtitle text"
    ))
    
    expect(page).to have_css('h1', text: 'Custom Title')
    expect(page).to have_css('p', text: 'Custom subtitle text')
  end
  
  it "renders a header with proper structure and styling" do
    render_inline(AppHeaderComponent.new)
    
    expect(page).to have_css('header.text-center')
    expect(page).to have_css('h1.text-4xl.font-bold')
    expect(page).to have_css('p.text-xl')
  end
end
