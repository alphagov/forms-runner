class CreateDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :deliveries do |t|
      t.string :delivery_reference
      t.datetime :delivered_at
      t.datetime :failed_at
      t.datetime :last_attempt_at
      t.string :failure_reason

      t.timestamps
    end

    add_index :deliveries, :delivery_reference
  end
end
