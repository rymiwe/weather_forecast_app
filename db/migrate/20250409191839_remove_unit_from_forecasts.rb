class RemoveUnitFromForecasts < ActiveRecord::Migration[7.1]
  def change
    remove_column :forecasts, :unit, :string
  end
end
