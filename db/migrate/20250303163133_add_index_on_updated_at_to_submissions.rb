class AddIndexOnUpdatedAtToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_index :submissions, :updated_at
  end
end
