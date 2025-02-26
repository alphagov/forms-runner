class SendSubmissionJob < ApplicationJob
  queue_as :default

  def perform(submission)
    mode = Mode.new(submission.mode)

    form = Api::V1::FormSnapshotRepository.find_with_mode(id: submission.form_id, mode:)

    answer_store = Store::DatabaseAnswerStore.new(submission.answers)

    journey = Flow::Journey.new(answer_store:, form:)

    # TODO: we can refactor how we do this - just getting it working
    mailer_options = FormSubmissionService::MailerOptions.new(title: form.name,
                                                              is_preview: mode.preview?,
                                                              timestamp: submission.created_at,
                                                              submission_reference: submission.reference,
                                                              payment_url: form.payment_url_with_reference(submission.reference))

    message_id = AwsSesSubmissionService.new(
      journey:,
      form:,
      mailer_options:,
    ).submit

    submission.update!(mail_message_id: message_id)
  end
end
