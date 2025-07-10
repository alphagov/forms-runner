class UpdateSubmissionFields < ActiveRecord::Migration[8.0]
  def change
    rename_column :submissions, :mail_status, :delivery_status
    rename_column :submissions, :sent_at, :last_delivery_attempt

    add_column :submissions, :delivered_at, :datetime, null: true
  end
end
