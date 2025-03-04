class AddModeToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :mode, :string
  end
end
