class CreateSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :submissions do |t|
      t.string :reference
      t.bigint :form_id
      t.string :mode
      t.jsonb :data

      t.timestamps
    end
  end
end
