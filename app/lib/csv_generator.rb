require "csv"

class CsvGenerator
  CSV_EXTENSION = ".csv".freeze
  CSV_FILENAME_PREFIX = "govuk_forms_".freeze

  def self.write_submission(all_steps:, submission_reference:, timestamp:, output_file_path:, is_s3_submission:)
    headers = [I18n.t("submission_csv.reference"), I18n.t("submission_csv.submitted_at")]
    values = [submission_reference, timestamp.iso8601]
    all_steps.map do |page|
      answer_parts = page.show_answer_in_csv(is_s3_submission)
      headers.push(*answer_parts.keys)
      values.push(*answer_parts.values)
    end

    CSV.open(output_file_path, "w") do |csv|
      csv << headers
      csv << values
    end
  end

  def self.csv_filename(form_title:, submission_reference:, max_length:)
    reference_part = "_#{submission_reference}"

    title_part_max_length = max_length - CSV_EXTENSION.length - CSV_FILENAME_PREFIX.length - reference_part.length

    title_part = form_title
      .parameterize(separator: "_")
      .truncate(title_part_max_length, separator: "_", omission: "")
    "#{CSV_FILENAME_PREFIX}#{title_part}#{reference_part}#{CSV_EXTENSION}"
  end
end
