class UpdateSubmissionFields < ActiveRecord::Migration[8.0]
  def change
    change_table :submissions, bulk: true do |t|
      t.string :delivery_status, default: "pending", null: false
      t.datetime :last_delivery_attempt, null: true
      t.datetime :delivered_at, null: true
    end
  end
end
