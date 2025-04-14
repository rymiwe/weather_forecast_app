# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchBarComponent, type: :component do
  it "renders the search bar with default values" do
    render_inline(SearchBarComponent.new(search_path: '/test/path'))
    
    expect(page).to have_css('form[action="/test/path"]')
    expect(page).to have_css('input[placeholder="Enter city, zip code, or address..."]')
    expect(page).to have_button('Get Forecast')
    expect(page).to have_css('svg') # Search icon
  end
  
  it "renders with custom placeholder text" do
    render_inline(SearchBarComponent.new(
      search_path: '/test/path',
      placeholder: "Search locations..."
    ))
    
    expect(page).to have_css('input[placeholder="Search locations..."]')
  end
  
  it "renders with custom button text" do
    render_inline(SearchBarComponent.new(
      search_path: '/test/path',
      button_text: "Search"
    ))
    
    expect(page).to have_button('Search')
  end
  
  it "applies custom classes to input and button" do
    render_inline(SearchBarComponent.new(
      search_path: '/test/path',
      input_classes: "test-input-class",
      button_classes: "test-button-class"
    ))
    
    expect(page).to have_css('input.test-input-class')
    expect(page).to have_css('button.test-button-class')
  end
  
  it "has responsive design classes" do
    render_inline(SearchBarComponent.new(search_path: '/test/path'))
    
    expect(page).to have_css('form.flex-col.md\\:flex-row')
  end
  
  it "includes proper accessibility attributes" do
    render_inline(SearchBarComponent.new(search_path: '/test/path'))
    
    expect(page).to have_css('input[aria-label="Enter location"][aria-describedby="search-help"]')
    expect(page).to have_css('label.sr-only')
  end
end
