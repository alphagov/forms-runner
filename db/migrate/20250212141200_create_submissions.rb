class CreateSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :submissions, &:timestamps
  end
end
