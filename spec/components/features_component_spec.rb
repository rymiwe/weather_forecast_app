require 'rails_helper'

RSpec.describe FeaturesComponent, type: :component do
  before do
    # Mock the FeatureCardComponent rendering
    allow_any_instance_of(FeatureCardComponent).to receive(:render_in).and_return("<div>Feature Card</div>")
  end
  
  it "renders the features section with default title" do
    render_inline(FeaturesComponent.new)
    
    expect(page).to have_css('section[aria-labelledby="features-heading"]')
    expect(page).to have_css('h2#features-heading', text: 'Key Features')
  end
  
  it "renders the features section with custom title" do
    render_inline(FeaturesComponent.new(title: "Custom Features"))
    
    expect(page).to have_css('h2#features-heading', text: 'Custom Features')
  end
  
  it "renders multiple feature cards" do
    # Test that the component renders FeatureCardComponent for each feature
    expect(FeatureCardComponent).to receive(:new).exactly(3).times.and_call_original
    
    render_inline(FeaturesComponent.new)
  end
  
  it "has a responsive grid layout" do
    render_inline(FeaturesComponent.new)
    
    expect(page).to have_css('.grid.grid-cols-1.md\\:grid-cols-3')
  end
  
  it "includes all three standard features" do
    component = FeaturesComponent.new
    features = component.instance_variable_get(:@features)
    
    expect(features.length).to eq(3)
    
    feature_titles = features.map { |f| f[:title] }
    expect(feature_titles).to include("Real-time Updates")
    expect(feature_titles).to include("Global Coverage")
    expect(feature_titles).to include("5-Day Forecast")
  end
end
