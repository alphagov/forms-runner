class AddBouncedAtColumnToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :bounced_at, :datetime
  end
end
