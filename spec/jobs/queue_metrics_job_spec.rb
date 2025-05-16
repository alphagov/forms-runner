require "rails_helper"

RSpec.describe QueueMetricsJob, type: :job do
  include ActiveJob::TestHelper

  let(:submission_queue_length) { 4 }

  before do
    allow(CloudWatchService).to receive(:record_queue_length_metric)

    mock_queue = instance_double(SolidQueue::Queue, size: submission_queue_length)
    allow(SolidQueue::Queue).to receive(:find_by_name).and_return(mock_queue)

    described_class.perform_later
    perform_enqueued_jobs
  end

  it "sends submission queue length to CloudWatch" do
    expect(CloudWatchService).to have_received(:record_queue_length_metric).with("submissions", submission_queue_length)
  end
end
