require "rails_helper"
require "aws-sdk-cloudwatch"

RSpec.describe CloudWatchService do
  let(:form_id) { 3 }
  let(:forms_env) { "test" }
  let(:cloudwatch_metrics_enabled) { true }

  before do
    allow(Settings).to receive_messages(forms_env:, cloudwatch_metrics_enabled:)
  end

  describe ".log_form_submission" do
    context "when CloudWatch metrics are disabled" do
      let(:cloudwatch_metrics_enabled) { false }

      it "does not call the CloudWatch client with .put_metric_data" do
        cloudwatch_client = Aws::CloudWatch::Client.new(stub_responses: true)
        allow(Aws::CloudWatch::Client).to receive(:new).and_return(cloudwatch_client)

        expect(cloudwatch_client).not_to receive(:put_metric_data)

        described_class.log_form_submission(form_id:)
      end
    end

    it "calls the cloudwatch client with put_metric_data" do
      # Stub the CloudWatch client and put_metric_data method
      cloudwatch_client = Aws::CloudWatch::Client.new(stub_responses: true)
      allow(Aws::CloudWatch::Client).to receive(:new).and_return(cloudwatch_client)

      expect(cloudwatch_client).to receive(:put_metric_data).with(
        namespace: "forms/#{forms_env}",
        metric_data: [
          {
            metric_name: "submitted",
            dimensions: [
              {
                name: "form_id",
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
        cloudwatch_client = Aws::CloudWatch::Client.new(stub_responses: true)
        allow(Aws::CloudWatch::Client).to receive(:new).and_return(cloudwatch_client)

        expect(cloudwatch_client).not_to receive(:put_metric_data)

        described_class.log_form_start(form_id:)
      end
    end

    it "calls the cloudwatch client with put_metric_data" do
      # Stub the CloudWatch client and put_metric_data method
      cloudwatch_client = Aws::CloudWatch::Client.new(stub_responses: true)
      allow(Aws::CloudWatch::Client).to receive(:new).and_return(cloudwatch_client)

      expect(cloudwatch_client).to receive(:put_metric_data).with(
        namespace: "forms/#{forms_env}",
        metric_data: [
          {
            metric_name: "started",
            dimensions: [
              {
                name: "form_id",
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
end
