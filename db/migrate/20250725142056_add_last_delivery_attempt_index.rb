class AddLastDeliveryAttemptIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :submissions, :last_delivery_attempt
  end
end
