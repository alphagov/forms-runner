class AddIndexOnCreatedAtAndFormIdAndModeToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_index :submissions, %i[created_at form_id mode]
  end
end
