class RemoveIsPreviewFromSubmissions < ActiveRecord::Migration[8.0]
  def change
    remove_column :submissions, :is_preview, :boolean
  end
end
