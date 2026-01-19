class JsonSubmissionGenerator
  def self.generate_submission(form:, all_steps:, submission_reference:, timestamp:, is_s3_submission:, submission_locale:)
    submission = {
      "$schema" => "#{Settings.forms_product_page.base_url}/json-submissions/v1/schema",
      form_name: form.name,
      submission_reference:,
      submitted_at: timestamp.getutc.iso8601(3),
      language: submission_locale,
      answers: all_steps.flat_map { |step| step.show_answer_in_json(is_s3_submission) },
    }
    JSON.pretty_generate(submission)
  end
end
