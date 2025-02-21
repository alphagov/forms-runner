class AddInitialColumnsToSubmissions < ActiveRecord::Migration[8.0]
  def change
    change_table :submissions, bulk: true do |t|
      t.string :reference
      t.string :mail_message_id
      t.integer :form_id
      t.jsonb :answers
      t.boolean :is_preview
    end
  end
end
