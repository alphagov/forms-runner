class QueueMetricsJob < ApplicationJob
  queue_as :metrics

  SUBMISSIONS_QUEUE_NAME = "submissions".freeze

  def perform(*_args)
    submissions_queue_length = SolidQueue::Queue.find_by_name(SUBMISSIONS_QUEUE_NAME).size
    CloudWatchService.record_queue_length_metric(SUBMISSIONS_QUEUE_NAME, submissions_queue_length)

    SolidQueue::FailedExecution.joins(:job)
                               .group_by { |failed_execution| failed_execution.job.queue_name }
                               .each do |queue_name, failed_executions|
                                 CloudWatchService.record_failed_job_executions(queue_name, failed_executions.count)
    end
  end
end
