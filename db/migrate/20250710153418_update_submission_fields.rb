class UpdateSubmissionFields < ActiveRecord::Migration[8.0]
  def change
    change_table :submissions, bulk: true do |t|
      t.rename :mail_status, :delivery_status
      t.rename :sent_at, :last_delivery_attempt
      t.datetime :delivered_at, null: true
      t.datetime :failed_at, null: true
      t.string :failure_reason, null: true
      t.string :confirmation_email, null: true
      t.datetime :confirmation_email_sent_at, null: true
    end
  end
end
