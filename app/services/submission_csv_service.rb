require "csv"
require "tempfile"

class SubmissionCsvService
  def initialize(current_context:, submission_reference:, timestamp:, output_file_path:)
    @current_context = current_context
    @submission_reference = submission_reference
    @timestamp = timestamp
    @output_file_path = output_file_path
  end

  def write
    headers = ["Reference", "Submitted at"]
    values = [@submission_reference, @timestamp.iso8601]
    @current_context.completed_steps.map do |page|
      headers << page.question_text
      values << page.show_answer
    end

    CSV.open(@output_file_path, "w") do |csv|
      csv << headers
      csv << values
    end
  end
end
