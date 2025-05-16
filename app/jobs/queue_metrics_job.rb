class QueueMetricsJob < ApplicationJob
  queue_as :metrics

  SUBMISSIONS_QUEUE_NAME = "submissions".freeze

  def perform(*_args)
    submissions_queue_length = SolidQueue::Queue.find_by_name(SUBMISSIONS_QUEUE_NAME).size
    CloudWatchService.record_queue_length_metric(SUBMISSIONS_QUEUE_NAME, submissions_queue_length)
  end
end
