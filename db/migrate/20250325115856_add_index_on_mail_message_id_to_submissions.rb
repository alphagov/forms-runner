class AddIndexOnMailMessageIdToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_index :submissions, :mail_message_id
  end
end
