class DropOldColumnsFromSubmissions < ActiveRecord::Migration[8.0]
  def change
    change_table :submissions, bulk: true do |t|
      t.remove :mail_status, type: :string
      t.remove :sent_at, type: :datetime
    end
  end
end
