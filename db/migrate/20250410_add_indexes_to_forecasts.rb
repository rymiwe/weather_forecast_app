class AddIndexesToForecasts < ActiveRecord::Migration[7.1]
  def change
    # Add composite index for zip_code and queried_at if it doesn't exist
    unless index_exists?(:forecasts, [:zip_code, :queried_at], name: 'index_forecasts_on_zip_and_time')
      add_index :forecasts, [:zip_code, :queried_at], name: 'index_forecasts_on_zip_and_time'
    end
    
    # Add index for timestamp-based queries if it doesn't exist
    unless index_exists?(:forecasts, :queried_at)
      add_index :forecasts, :queried_at, name: 'index_forecasts_on_queried_at'
    end
  end
end
