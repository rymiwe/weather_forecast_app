class CreateForecasts < ActiveRecord::Migration[7.1]
  def change
    create_table :forecasts do |t|
      t.string :address
      t.string :zip_code
      t.float :current_temp
      t.float :high_temp
      t.float :low_temp
      t.string :conditions
      t.text :extended_forecast
      t.datetime :queried_at

      t.timestamps
    end
    
    # Add indices for better query performance
    add_index :forecasts, :zip_code
    add_index :forecasts, :queried_at
    add_index :forecasts, [:zip_code, :queried_at]
  end
end
