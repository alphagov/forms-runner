namespace :submissions do
  desc "Retry bounced submissions"
  task :retry_bounced_submissions, %i[form_id] => :environment do |_, args|
    form_id = args[:form_id]

    usage_message = "usage: rake submissions:retry_bounced_submissions[<form_id>]".freeze
    abort usage_message if form_id.blank?

    submissions_to_retry = Submission.where(form_id: form_id)
                                      .where(mail_status: "bounced")

    Rails.logger.info "#{submissions_to_retry.length} submissions to retry for form with ID: #{form_id}"

    submissions_to_retry.each do |submission|
      Rails.logger.info "Retrying submission with reference #{submission.reference} for form with ID: #{form_id}"
      SendSubmissionJob.perform_later(submission)
    end
  end
end
