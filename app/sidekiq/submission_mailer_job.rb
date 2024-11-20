class SubmissionMailerJob
  include Sidekiq::Job

  def perform(session_data, timestamp_string, submission_reference, notify_email_reference, form_id, mode_string)
    mode = Mode.new(mode_string)
    timestamp = ActiveSupport::TimeZone[timezone].parse(timestamp_string)

    form = Api::V1::FormSnapshotRepository.find_with_mode(id: form_id, mode:)
    context = Flow::Context.new(form:, store: HashWithIndifferentAccess.new(session_data))

    mailer_options = FormSubmissionService::MailerOptions.new(title: form.name,
      preview_mode: mode.preview?,
      timestamp:,
      submission_reference:,
      payment_url: form.payment_url_with_reference(submission_reference))

    NotifySubmissionService.new(
      current_context: context,
      notify_email_reference: notify_email_reference,
      mailer_options:,
    ).submit
  end

  def timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end
end
