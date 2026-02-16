class QueueMetricsJob < ApplicationJob
  queue_as :metrics

  SUBMISSIONS_QUEUE_NAME = "submissions".freeze

  def perform(*_args)
    submissions_queue_length = SolidQueue::Queue.find_by_name(SUBMISSIONS_QUEUE_NAME).size
    CloudWatchService.record_queue_length_metric(SUBMISSIONS_QUEUE_NAME, submissions_queue_length)

    # rubocop:disable Rails/FindEach
    SolidQueue::Queue.all.each do |queue|
      failed_executions_count = SolidQueue::FailedExecution.joins(:job).where(solid_queue_jobs: { queue_name: queue.name }).count
      CloudWatchService.record_failed_job_executions(queue.name, failed_executions_count)
    end
    # rubocop:enable Rails/FindEach
  end
end
