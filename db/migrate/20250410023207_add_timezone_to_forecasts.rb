class AddTimezoneToForecasts < ActiveRecord::Migration[7.1]
  def change
    add_column :forecasts, :timezone, :string
  end
end
