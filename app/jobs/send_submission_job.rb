class SendSubmissionJob < ApplicationJob
  queue_as :default

  def perform(submission)
    mode = Mode.new(submission.mode)

    form = Api::V1::FormSnapshotRepository.find_with_mode(id: submission.form_id, mode:)
    context = Flow::Context.new(form:, store: HashWithIndifferentAccess.new(submission.data))

    # TODO: we can refactor how we do this - just getting it working
    mailer_options = FormSubmissionService::MailerOptions.new(title: form.name,
                                                              preview_mode: mode.preview?,
                                                              timestamp: submission.created_at,
                                                              submission_reference: submission.reference,
                                                              payment_url: form.payment_url_with_reference(submission.reference))

    NotifySubmissionService.new(
      current_context: context,
      notify_email_reference: submission.reference, # this won't be needed for SES - just use submission reference
      mailer_options:,
      ).submit
  end
end
