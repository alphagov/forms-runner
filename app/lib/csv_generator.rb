require "csv"

class CsvGenerator
  def self.generate_submission(all_steps:, submission_reference:, timestamp:, is_s3_submission:)
    headers = [I18n.t("submission_csv.reference"), I18n.t("submission_csv.submitted_at")]
    values = [submission_reference, timestamp.iso8601]
    all_steps.map do |step|
      answer_parts = step.show_answer_in_csv(is_s3_submission)
      headers.push(*answer_parts.keys)
      values.push(*answer_parts.values)
    end

    CSV.generate do |csv|
      csv << headers
      csv << values
    end
  end
end
