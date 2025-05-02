require "rails_helper"
require "aws-sdk-cloudwatch"

RSpec.describe CloudWatchService do
  let(:form_id) { 3 }
  let(:forms_env) { "test" }
  let(:cloudwatch_metrics_enabled) { true }
  let(:cloudwatch_client) { Aws::CloudWatch::Client.new(stub_responses: true) }
  let(:job_name) { "AJobName" }

  before do
    allow(Settings).to receive_messages(forms_env:, cloudwatch_metrics_enabled:)
    allow(Aws::CloudWatch::Client).to receive(:new).and_return(cloudwatch_client)
  end

  describe ".log_form_submission" do
    context "when CloudWatch metrics are disabled" do
      let(:cloudwatch_metrics_enabled) { false }

      it "does not call the CloudWatch client with .put_metric_data" do
        expect(cloudwatch_client).not_to receive(:put_metric_data)

        described_class.log_form_submission(form_id:)
      end
    end

    it "calls the cloudwatch client with put_metric_data" do
      expect(cloudwatch_client).to receive(:put_metric_data).once.with(
        namespace: "Forms",
        metric_data: [
          {
            metric_name: "Submitted",
            dimensions: [
              {
                name: "Environment",
                value: forms_env,
              },
              {
                name: "FormId",
                value: form_id.to_s,
              },
            ],
            value: 1,
            unit: "Count",
          },
        ],
      )

      described_class.log_form_submission(form_id:)
    end
  end

  describe ".log_form_start" do
    context "when CloudWatch metrics are disabled" do
      let(:cloudwatch_metrics_enabled) { false }

      it "does not call the CloudWatch client with .put_metric_data" do
        expect(cloudwatch_client).not_to receive(:put_metric_data)

        described_class.log_form_start(form_id:)
      end
    end

    it "calls the cloudwatch client with put_metric_data" do
      expect(cloudwatch_client).to receive(:put_metric_data).once.with(
        namespace: "Forms",
        metric_data: [
          {
            metric_name: "Started",
            dimensions: [
              {
                name: "Environment",
                value: forms_env,
              },
              {
                name: "FormId",
                value: form_id.to_s,
              },
            ],
            value: 1,
            unit: "Count",
          },
        ],
      )

      described_class.log_form_start(form_id:)
    end
  end

  describe ".log_submission_sent" do
    let(:milliseconds_since_scheduled) { 1000 }

    context "when CloudWatch metrics are disabled" do
      let(:cloudwatch_metrics_enabled) { false }

      it "does not call the CloudWatch client with .put_metric_data" do
        expect(cloudwatch_client).not_to receive(:put_metric_data)

        described_class.log_submission_sent(milliseconds_since_scheduled)
      end
    end

    it "calls the cloudwatch client with put_metric_data" do
      expect(cloudwatch_client).to receive(:put_metric_data).with(
        namespace: "Forms/Jobs",
        metric_data: [
          {
            metric_name: "TimeToSendSubmission",
            dimensions: [
              {
                name: "Environment",
                value: forms_env,
              },
              {
                name: "ServiceName",
                value: "forms-runner",
              },
              {
                name: "JobName",
                value: "SendSubmissionJob",
              },
            ],
            value: milliseconds_since_scheduled,
            unit: "Milliseconds",
          },
        ],
      )

      described_class.log_submission_sent(milliseconds_since_scheduled)
    end
  end

  describe ".log_job_failure" do
    context "when CloudWatch metrics are disabled" do
      let(:cloudwatch_metrics_enabled) { false }

      it "does not call the CloudWatch client with .put_metric_data" do
        expect(cloudwatch_client).not_to receive(:put_metric_data)

        described_class.log_job_failure(job_name)
      end
    end

    it "calls the cloudwatch client with put_metric_data" do
      expect(cloudwatch_client).to receive(:put_metric_data).with(
        namespace: "Forms/Jobs",
        metric_data: [
          {
            metric_name: "Failure",
            dimensions: [
              {
                name: "Environment",
                value: forms_env,
              },
              {
                name: "ServiceName",
                value: "forms-runner",
              },
              {
                name: "JobName",
                value: job_name,
              },
            ],
            value: 1,
            unit: "Count",
          },
        ],
      )

      described_class.log_job_failure(job_name)
    end
  end

  describe ".log_job_started" do
    context "when CloudWatch metrics are disabled" do
      let(:cloudwatch_metrics_enabled) { false }

      it "does not call the CloudWatch client with .put_metric_data" do
        expect(cloudwatch_client).not_to receive(:put_metric_data)

        described_class.log_job_started(job_name)
      end
    end

    it "calls the cloudwatch client with put_metric_data" do
      expect(cloudwatch_client).to receive(:put_metric_data).with(
        namespace: "Forms/Jobs",
        metric_data: [
          {
            metric_name: "Started",
            dimensions: [
              {
                name: "Environment",
                value: forms_env,
              },
              {
                name: "ServiceName",
                value: "forms-runner",
              },
              {
                name: "JobName",
                value: job_name,
              },
            ],
            value: 1,
            unit: "Count",
          },
        ],
      )

      described_class.log_job_started(job_name)
    end
  end

  describe ".log_queue_length" do
    let(:queue_name) { "test-queue" }
    let(:queue_length) { 42 }

    context "when CloudWatch metrics are disabled" do
      let(:cloudwatch_metrics_enabled) { false }

      it "does not call the CloudWatch client with .put_metric_data" do
        expect(cloudwatch_client).not_to receive(:put_metric_data)

        described_class.log_queue_length(queue_name, queue_length)
      end
    end

    it "calls the cloudwatch client with put_metric_data" do
      expect(cloudwatch_client).to receive(:put_metric_data).with(
        namespace: "Forms/Jobs",
        metric_data: [
          {
            metric_name: "QueueLength",
            dimensions: [
              {
                name: "Environment",
                value: forms_env,
              },
              {
                name: "ServiceName",
                value: "forms-runner",
              },
              {
                name: "QueueName",
                value: queue_name,
              },
            ],
            value: queue_length,
            unit: "Count",
          },
        ],
      )

      described_class.log_queue_length(queue_name, queue_length)
    end
  end
end
