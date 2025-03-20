class AddMailStatusToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :mail_status, :string, default: "pending", null: false
    add_index :submissions, :mail_status
  end
end
