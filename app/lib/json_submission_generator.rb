class JsonSubmissionGenerator
  def self.generate_submission(submission:, is_s3_submission:)
    form = submission.form

    submission_hash = {
      "$schema" => "#{Settings.forms_product_page.base_url}/json-submissions/v1/schema",
      form_name: form.name,
      submission_reference: submission.reference,
      submitted_at: submission.submission_time.getutc.iso8601(3),
      answers: submission.journey.all_steps.flat_map { |step| step.show_answer_in_json(submission_reference: submission.reference, is_s3_submission:) },
    }

    if form.multilingual?
      submission_hash[:language] = submission.submission_locale
    end

    JSON.pretty_generate(submission_hash)
  end
end
