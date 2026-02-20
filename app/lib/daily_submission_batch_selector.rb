class DailySubmissionBatchSelector
  Batch = Data.define(:form_id, :mode, :submissions)

  class << self
    def batches(date)
      Enumerator.new do |yielder|
        form_ids_and_modes_with_send_daily_submission_batch(date).each do |form_id, mode|
          submissions = Submission.for_form_and_mode(form_id, mode).on_day(date).order(created_at: :desc)

          # If the send_daily_submission_batch has been disabled part-way through the day, don't send the batch even
          # if there are some submissions where the form_document has it enabled.
          next unless submissions.any? && submissions.first.form_document["send_daily_submission_batch"] == true

          yielder << Batch.new(form_id, mode, submissions)
        end
      end
    end

  private

    def form_ids_and_modes_with_send_daily_submission_batch(date)
      # Get all form_ids and modes that have at least one submission on the date with send_daily_submission_batch
      # set to true.
      Submission.on_day(date)
                .where("(form_document->>'send_daily_submission_batch')::boolean = true")
                .distinct
                .pluck(:form_id, :mode)
    end
  end
end
