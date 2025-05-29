class UpdateMailStatusForPendingSubmissions < ActiveRecord::Migration[8.0]
  def change
    Submission.where(mail_status: :delivered).update_all(mail_status: :pending)
  end
end
