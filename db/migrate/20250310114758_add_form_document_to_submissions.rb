class AddFormDocumentToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :form_document, :jsonb
  end
end
