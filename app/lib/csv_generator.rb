require "csv"

class CsvGenerator
  CSV_EXTENSION = ".csv".freeze
  CSV_FILENAME_PREFIX = "govuk_forms_".freeze

  def self.write_submission(current_context:, submission_reference:, timestamp:, output_file_path:)
    headers = ["Reference", "Submitted at"]
    values = [submission_reference, timestamp.iso8601]
    current_context.completed_steps.map do |page|
      headers.push(*page.show_answer_in_csv.keys)
      values.push(*page.show_answer_in_csv.values)
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
