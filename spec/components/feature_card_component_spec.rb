require 'rails_helper'

RSpec.describe FeatureCardComponent, type: :component do
  it "renders a feature card with the provided content" do
    render_inline(FeatureCardComponent.new(
      title: "Test Feature",
      description: "This is a test feature description",
      icon_path: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
    ))
    
    expect(page).to have_css('h3', text: 'Test Feature')
    expect(page).to have_css('p', text: 'This is a test feature description')
    expect(page).to have_css('svg path[d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"]')
  end
  
  it "has the correct styling classes" do
    render_inline(FeatureCardComponent.new(
      title: "Test Feature",
      description: "This is a test feature description",
      icon_path: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
    ))
    
    expect(page).to have_css('div.bg-white.p-6.rounded-lg.shadow-md')
    expect(page).to have_css('div.text-blue-600.mb-4')
    expect(page).to have_css('h3.text-lg.font-semibold.mb-2')
    expect(page).to have_css('p.text-gray-600')
  end
  
  it "has the correct icon size" do
    render_inline(FeatureCardComponent.new(
      title: "Test Feature",
      description: "This is a test feature description",
      icon_path: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
    ))
    
    expect(page).to have_css('svg.h-10.w-10')
  end
end
