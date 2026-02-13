class AddBatchFrequencyToDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :deliveries, :batch_frequency, :string
  end
end
