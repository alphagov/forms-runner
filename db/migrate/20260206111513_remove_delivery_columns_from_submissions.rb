class RemoveDeliveryColumnsFromSubmissions < ActiveRecord::Migration[8.1]
  def change
    change_table :submissions, bulk: true do |t|
      t.remove :bounced_at, type: :datetime
      t.remove :delivered_at, type: :datetime
      t.remove :delivery_status, type: :string
      t.remove :last_delivery_attempt, type: :datetime
      t.remove :mail_message_id, type: :string
    end
  end
end
