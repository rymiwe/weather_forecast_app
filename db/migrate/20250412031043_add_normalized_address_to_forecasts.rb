class AddNormalizedAddressToForecasts < ActiveRecord::Migration[7.1]
  def change
    add_column :forecasts, :normalized_address, :string
    add_index :forecasts, :normalized_address
  end
end
