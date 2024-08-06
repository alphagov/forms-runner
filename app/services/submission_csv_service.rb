require "csv"
require "tempfile"

class SubmissionCsvService
  def initialize(current_context:, submission_reference:, output_file_path:)
    @current_context = current_context
    @submission_reference = submission_reference
    @output_file_path = output_file_path
  end

  def write
    headers = %w[Reference]
    values = [@submission_reference]
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
