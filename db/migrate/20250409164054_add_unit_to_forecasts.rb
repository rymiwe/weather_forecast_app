class AddUnitToForecasts < ActiveRecord::Migration[7.1]
  def change
    add_column :forecasts, :unit, :string
  end
end
