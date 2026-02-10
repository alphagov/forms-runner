require "csv"

class CsvGenerator
  def self.generate_submission(submission:, is_s3_submission:)
    headers = [I18n.t("submission_csv.reference"), I18n.t("submission_csv.submitted_at")]
    values = [submission.reference, submission.submission_time.iso8601]
    submission.journey.all_steps.map do |step|
      answer_parts = step.show_answer_in_csv(is_s3_submission)
      headers.push(*answer_parts.keys)
      values.push(*answer_parts.values)
    end

    if submission.form.multilingual?
      headers.push(I18n.t("submission_csv.language"))
      values.push(submission.submission_locale)
    end

    CSV.generate do |csv|
      csv << headers
      csv << values
    end
  end
end
