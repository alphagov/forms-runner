require "rails_helper"

RSpec.describe QueueMetricsJob, type: :job do
  include ActiveJob::TestHelper

  let(:submission_queue_length) { 4 }

  before do
    allow(CloudWatchService).to receive(:record_queue_length_metric)

    mock_queue = instance_double(SolidQueue::Queue, size: submission_queue_length)
    allow(SolidQueue::Queue).to receive(:find_by_name).and_return(mock_queue)

    described_class.perform_later
  end

  describe "submission queue length metric" do
    it "sends submission queue length to CloudWatch" do
      perform_enqueued_jobs
      expect(CloudWatchService).to have_received(:record_queue_length_metric).with("submissions", submission_queue_length)
    end
  end

  describe "failed executions metric" do
    let(:queue_name) { "queue-1" }
    let(:other_queue_name) { "queue-2" }

    before do
      allow(CloudWatchService).to receive(:record_failed_job_executions)

      create :solid_queue_failed_execution, job: create(:solid_queue_job, queue_name:)
      create :solid_queue_failed_execution, job: create(:solid_queue_job, queue_name:)
      create :solid_queue_failed_execution, job: create(:solid_queue_job, queue_name: other_queue_name)
      create(:solid_queue_job, queue_name:)
    end

    it "sends the count of failed executions for each queue to CloudWatch" do
      perform_enqueued_jobs
      expect(CloudWatchService).to have_received(:record_failed_job_executions).with(queue_name, 2)
      expect(CloudWatchService).to have_received(:record_failed_job_executions).with(other_queue_name, 1)
    end
  end
end
