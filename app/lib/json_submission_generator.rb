class JsonSubmissionGenerator
  def self.generate_submission(form:, all_steps:, submission_reference:, timestamp:, is_s3_submission:)
    submission = {
      form_name: form.name,
      form_id: form.id.to_s,
      submission_reference:,
      submitted_at: timestamp.getutc,
      answers: all_steps.map do |step|
        {
          question_id: step.page_id,
          question_text: step.question_text,
          answer_type: step.page.answer_type,
          **step.show_answer_in_json(is_s3_submission),
        }
      end,
    }
    submission.to_json
  end
end
