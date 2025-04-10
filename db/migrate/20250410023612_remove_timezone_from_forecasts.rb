class RemoveTimezoneFromForecasts < ActiveRecord::Migration[7.1]
  def change
    remove_column :forecasts, :timezone, :string
  end
end
