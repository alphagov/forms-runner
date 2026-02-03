namespace :data_migrations do
  desc "Create delivery records for existing submissions"
  task create_deliveries: :environment do
    submissions = Submission.left_outer_joins(:submission_deliveries).where(submission_deliveries: { id: nil })
    Rails.logger.info "Total submissions in database: #{Submission.count}"
    Rails.logger.info "Found #{submissions.count} submissions without delivery records"

    created_deliveries = 0
    submissions.find_each do |submission|
      submission.deliveries.create!(
        created_at: submission.created_at,
        delivery_reference: submission.mail_message_id,
        delivered_at: submission.delivered_at,
        last_attempt_at: submission.last_delivery_attempt,
        failed_at: submission.bounced_at,
        failure_reason: submission.bounced? ? "bounced" : nil,
      )
      created_deliveries += 1
    rescue StandardError => e
      Rails.logger.error "Failed to create delivery for submission #{submission.reference}: #{e.message}"
    end

    Rails.logger.info "Created #{created_deliveries} delivery records"
  end
end
