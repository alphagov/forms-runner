class AddSentAtToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :sent_at, :datetime
    add_index :submissions, :sent_at
  end
end
