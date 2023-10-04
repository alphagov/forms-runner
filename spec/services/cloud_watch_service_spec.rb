require "rails_helper"
require "aws-sdk-cloudwatch"

RSpec.describe CloudWatchService do
  describe ".submitted" do
    let(:form_id) { 3 }
    let(:forms_env) { "test" }

    before do
      allow(Settings).to receive(:forms_env).and_return(forms_env)
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
end
