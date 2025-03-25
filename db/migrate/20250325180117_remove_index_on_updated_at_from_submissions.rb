class RemoveIndexOnUpdatedAtFromSubmissions < ActiveRecord::Migration[8.0]
  def change
    remove_index :submissions, :updated_at
  end
end
