require 'rails_helper'

RSpec.describe TemperatureHelper, type: :helper do
  describe "#display_temperature" do
    before do
      # Create a session mock for testing
      allow(helper).to receive(:session).and_return({})
    end

    context "with imperial units" do
      it "formats temperature in Fahrenheit with degree symbol" do
        # Current temperature is stored in Celsius (integer)
        celsius_temp = 20 # 68°F
        
        # Display with imperial units (Fahrenheit)
        result = helper.display_temperature(celsius_temp, 'imperial')
        
        # Should convert to Fahrenheit and append °F
        expect(result).to eq("68°F")
      end
      
      it "handles negative temperatures" do
        # -10°C is 14°F
        result = helper.display_temperature(-10, 'imperial')
        expect(result).to eq("14°F")
      end
      
      it "handles zero temperature" do
        # 0°C is 32°F
        result = helper.display_temperature(0, 'imperial')
        expect(result).to eq("32°F")
      end
      
      it "applies custom CSS classes" do
        result = helper.display_temperature(20, 'imperial', size: 'lg')
        expect(result).to include('text-lg')
        expect(result).to include('68°F')
      end
    end
    
    context "with metric units" do
      it "formats temperature in Celsius with degree symbol" do
        # Temperature already stored in Celsius
        celsius_temp = 25
        
        # Display with metric units (Celsius)
        result = helper.display_temperature(celsius_temp, 'metric')
        
        # Should keep as Celsius and append °C
        expect(result).to eq("25°C")
      end
      
      it "handles negative temperatures" do
        result = helper.display_temperature(-15, 'metric')
        expect(result).to eq("-15°C")
      end
      
      it "handles zero temperature" do
        result = helper.display_temperature(0, 'metric')
        expect(result).to eq("0°C")
      end
      
      it "applies custom CSS classes" do
        result = helper.display_temperature(20, 'metric', size: 'lg')
        expect(result).to include('text-lg')
        expect(result).to include('20°C')
      end
    end
    
    context "with nil or invalid inputs" do
      it "returns 'N/A' for nil temperature" do
        expect(helper.display_temperature(nil, 'imperial')).to eq("N/A")
        expect(helper.display_temperature(nil, 'metric')).to eq("N/A")
      end
      
      it "returns temperature in Celsius when units is nil" do
        # Default should be metric (Celsius)
        expect(helper.display_temperature(25, nil)).to eq("25°C")
      end
      
      it "returns temperature in Celsius for unknown unit type" do
        # Unknown unit type should default to metric
        expect(helper.display_temperature(25, 'unknown')).to eq("25°C")
      end
      
      it "handles nil options gracefully" do
        # Testing with nil options (not with a 4th parameter)
        expect(helper.display_temperature(25, 'metric', nil)).to include("25°C")
      end
    end
    
    context "with session-based units" do
      it "uses imperial units from session when no units specified" do
        allow(helper).to receive(:session).and_return({ temperature_units: 'imperial' })
        
        # When units parameter is not provided, it should use session value
        result = helper.display_temperature(20, nil)
        
        expect(result).to eq("68°F")
      end
      
      it "uses metric units from session when no units specified" do
        allow(helper).to receive(:session).and_return({ temperature_units: 'metric' })
        
        # When units parameter is not provided, it should use session value
        result = helper.display_temperature(20, nil)
        
        expect(result).to eq("20°C")
      end
      
      it "explicitly provided units take precedence over session" do
        # Session has imperial
        allow(helper).to receive(:session).and_return({ temperature_units: 'imperial' })
        
        # But we explicitly request metric
        result = helper.display_temperature(20, 'metric')
        
        # Should use metric as specified, not session value
        expect(result).to eq("20°C")
      end
    end
  end
end
