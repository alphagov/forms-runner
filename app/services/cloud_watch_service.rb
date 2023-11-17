class CloudWatchService
  REGION = "eu-west-2".freeze

  def self.log_form_submission(form_id:)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: metric_namespace,
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
  end

  def self.log_form_start(form_id:)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: metric_namespace,
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
  end

  def self.metric_namespace
    "forms/#{Settings.forms_env}".downcase
  end

  def self.cloudwatch_client
    Aws::CloudWatch::Client.new(region: REGION)
  end
end
