class UpdateSubmissionFields < ActiveRecord::Migration[8.0]
  def change
    rename_column :submissions, :mail_status, :delivery_status

    change_table :submissions, bulk: true do |t|
      t.datetime :last_delivery_attempt, null: true
      t.datetime :delivered_at, null: true
    end
  end
end
