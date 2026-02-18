class QueueMetricsJob < ApplicationJob
  queue_as :metrics

  def perform(*_args)
    # rubocop:disable Rails/FindEach
    SolidQueue::Queue.all.each do |queue|
      CloudWatchService.record_queue_length_metric(queue.name, queue.size)
      failed_executions_count = SolidQueue::FailedExecution.joins(:job).where(solid_queue_jobs: { queue_name: queue.name }).count
      CloudWatchService.record_failed_job_executions(queue.name, failed_executions_count)
    end
    # rubocop:enable Rails/FindEach
  end
end
