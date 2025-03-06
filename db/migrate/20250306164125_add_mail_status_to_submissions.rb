class AddMailStatusToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :mail_status, :string
  end
end
