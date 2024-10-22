require "csv"

class CsvGenerator
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
end
