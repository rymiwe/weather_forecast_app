class ChangeTemperatureColumnsToInteger < ActiveRecord::Migration[7.0]
  def up
    # First round existing float values to integers
    Forecast.find_each do |forecast|
      forecast.update_columns(
        current_temp: forecast.current_temp&.round,
        high_temp: forecast.high_temp&.round,
        low_temp: forecast.low_temp&.round
      )
    end
    
    # Change column types
    change_column :forecasts, :current_temp, :integer
    change_column :forecasts, :high_temp, :integer
    change_column :forecasts, :low_temp, :integer
  end
  
  def down
    change_column :forecasts, :current_temp, :float
    change_column :forecasts, :high_temp, :float
    change_column :forecasts, :low_temp, :float
  end
end
