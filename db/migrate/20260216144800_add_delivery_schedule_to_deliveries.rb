class AddDeliveryScheduleToDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :deliveries, :delivery_schedule, :string, null: false, default: "immediate", comment: "Either 'immediate' if the delivery is for a single submission or a value representing the schedule for sending multiple submissions."
  end
end
