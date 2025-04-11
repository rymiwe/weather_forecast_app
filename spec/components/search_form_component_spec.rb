require 'rails_helper'

RSpec.describe SearchFormComponent, type: :component do
  it "renders the search form with the correct path" do
    render_inline(SearchFormComponent.new(search_path: '/test/path'))
    
    expect(page).to have_css('form[action="/test/path"]')
    expect(page).to have_css('input[type="text"][name="address"]')
    expect(page).to have_css('button[type="submit"]')
  end
  
  it "includes the search help text" do
    render_inline(SearchFormComponent.new(search_path: '/test/path'))
    
    expect(page).to have_css('p#search-help')
    expect(page).to have_content('Enter a city name, zip code, or complete address')
  end
  
  it "sets appropriate ARIA attributes for accessibility" do
    render_inline(SearchFormComponent.new(search_path: '/test/path'))
    
    expect(page).to have_css('section[aria-labelledby="search-heading"]')
    expect(page).to have_css('h2#search-heading.sr-only')
    expect(page).to have_css('input[aria-label="Enter location"][aria-describedby="search-help"]')
  end
  
  it "includes a responsive form layout" do
    render_inline(SearchFormComponent.new(search_path: '/test/path'))
    
    expect(page).to have_css('form.flex-col.md\\:flex-row')
  end
end
