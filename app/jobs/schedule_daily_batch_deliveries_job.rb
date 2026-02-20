class ScheduleDailyBatchDeliveriesJob < ApplicationJob
  # If we change the queue for this job, ensure we add a new alert in CloudWatch for failed executions
  queue_as :submissions

  def perform
    CloudWatchService.record_job_started_metric(self.class.name)
    CurrentJobLoggingAttributes.job_class = self.class.name
    CurrentJobLoggingAttributes.job_id = job_id

    date = Time.zone.yesterday

    DailySubmissionBatchSelector.batches(date).each do |batch|
      existing_deliveries = batch.submissions.first.deliveries.daily
      if existing_deliveries.any?
        Rails.logger.warn("Daily batch delivery already exists for batch - skipping", {
          form_id: batch.form_id, mode: batch.mode, date:, delivery_id: existing_deliveries.first.id
        })
        next
      end

      delivery = Delivery.create!(delivery_schedule: :daily, submissions: batch.submissions)

      send_batch_job = SendSubmissionBatchJob.perform_later(delivery:)

      Rails.logger.info("Scheduled SendSubmissionBatchJob to send daily submission batch", {
        form_id: batch.form_id, mode: batch.mode, date: date, job_id: send_batch_job.job_id, delivery_id: delivery.id
      })
    end
  end
end
