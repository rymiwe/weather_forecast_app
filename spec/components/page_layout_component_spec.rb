# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PageLayoutComponent, type: :component do
  before do
    # Mock the FooterComponent rendering
    allow_any_instance_of(FooterComponent).to receive(:render_in).and_return("<footer>Footer Content</footer>")
  end
  
  it "renders with default background and container classes" do
    component = PageLayoutComponent.new
    
    # Test with block content
    render_inline(component) do |c|
      c.with_content { "Main content" }
    end
    
    expect(page).to have_css('.min-h-screen.bg-gradient-to-b.from-blue-50.to-white')
    expect(page).to have_css('.container.mx-auto.px-4.py-8')
    expect(page).to have_content("Main content")
    expect(page).to have_css("footer", text: "Footer Content")
  end
  
  it "renders with custom background classes" do
    component = PageLayoutComponent.new(background_classes: "custom-bg")
    
    render_inline(component) do |c|
      c.with_content { "Main content" }
    end
    
    expect(page).to have_css('.custom-bg')
    expect(page).not_to have_css('.min-h-screen.bg-gradient-to-b')
  end
  
  it "renders with custom container classes" do
    component = PageLayoutComponent.new(container_classes: "custom-container")
    
    render_inline(component) do |c|
      c.with_content { "Main content" }
    end
    
    expect(page).to have_css('.container.custom-container')
  end
  
  it "renders with header content" do
    component = PageLayoutComponent.new
    
    render_inline(component) do |c|
      c.with_header { "<h1>Page Title</h1>".html_safe }
      c.with_content { "Main content" }
    end
    
    expect(page).to have_css('h1', text: 'Page Title')
    expect(page).to have_content("Main content")
  end
  
  it "renders without header content" do
    component = PageLayoutComponent.new
    
    render_inline(component) do |c|
      c.with_content { "Main content" }
    end
    
    expect(page).to have_content("Main content")
    expect(page).not_to have_css('header')
  end
end
