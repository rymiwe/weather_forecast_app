require 'rails_helper'

RSpec.describe ForecastsHelper, type: :helper do
  describe "#format_conditions" do
    context "with a single condition string" do
      it "capitalizes each word" do
        expect(helper.format_conditions("clear sky")).to eq("Clear Sky")
      end
      
      it "handles already capitalized words" do
        expect(helper.format_conditions("Clear Sky")).to eq("Clear Sky")
      end
      
      it "handles mixed capitalization" do
        expect(helper.format_conditions("parTLy cloUDy")).to eq("Partly Cloudy")
      end
      
      it "handles empty string" do
        expect(helper.format_conditions("")).to eq("")
      end
      
      it "handles nil" do
        expect(helper.format_conditions(nil)).to eq("")
      end
    end
    
    context "with an array of conditions" do
      it "formats and joins multiple conditions" do
        conditions = ["light rain", "cloudy", "WINDY"]
        expect(helper.format_conditions(conditions)).to eq("Light Rain, Cloudy, Windy")
      end
      
      it "handles an empty array" do
        expect(helper.format_conditions([])).to eq("")
      end
      
      it "handles array with some nil or empty values" do
        conditions = ["light rain", nil, "", "fog"]
        expect(helper.format_conditions(conditions)).to eq("Light Rain, , , Fog")
      end
    end
  end
end
