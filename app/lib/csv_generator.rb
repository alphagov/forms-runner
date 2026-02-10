require "csv"

class CsvGenerator
  class << self
    def generate_submission(submission:, is_s3_submission:)
      CSV.generate do |csv|
        csv << headers(submission, is_s3_submission)
        csv << values_for_submission(submission, is_s3_submission)
      end
    end

    def generate_batched_submissions(submissions:, is_s3_submission:)
      CSV.generate do |csv|
        csv << headers(submissions.first, is_s3_submission)
        submissions.each do |submission|
          csv << values_for_submission(submission, is_s3_submission)
        end
      end
    end

  private

    def headers(submission, is_s3_submission)
      headers = [I18n.t("submission_csv.reference"), I18n.t("submission_csv.submitted_at")]

      submission.journey.all_steps.each do |step|
        headers.push(*step.show_answer_in_csv(submission_reference: submission.reference, is_s3_submission:).keys)
      end

      if submission.form.multilingual?
        headers.push(I18n.t("submission_csv.language"))
      end

      headers
    end

    def values_for_submission(submission, is_s3_submission)
      values = [submission.reference, submission.submission_time.iso8601]

      submission.journey.all_steps.each do |step|
        answer_parts = step.show_answer_in_csv(submission_reference: submission.reference, is_s3_submission:)
        values.push(*answer_parts.values)
      end

      if submission.form.multilingual?
        values.push(submission.submission_locale)
      end

      values
    end
  end
end
