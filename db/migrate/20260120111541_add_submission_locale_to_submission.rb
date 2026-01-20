class AddSubmissionLocaleToSubmission < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :submission_locale, :string, null: false, default: "en", comment: "The language the form was submitted in ISO 2 letter format. Normally either 'en' or 'cy'"
  end
end
