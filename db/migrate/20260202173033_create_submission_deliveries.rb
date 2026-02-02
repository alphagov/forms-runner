class CreateSubmissionDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :submission_deliveries do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :delivery, null: false, foreign_key: true

      t.timestamps
    end
  end
end
