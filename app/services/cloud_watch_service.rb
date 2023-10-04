class CloudWatchService
  def self.log_form_submission(form_id:)
    region = "eu-west-2"
    cloudwatch_client = Aws::CloudWatch::Client.new(region:)
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

  def self.metric_namespace
    "forms/#{Settings.forms_env}".downcase
  end
end
