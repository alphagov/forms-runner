class CloudWatchService
  self.submitted?
    cloudwatch_client.put_metric_data(
      namespace: metric_namespace,
      metric_data: [
        {
          metric_name: metric_name,
          dimensions: [
            {
              name: dimension_name,
              value: dimension_value
            }
          ],
          value: metric_value,
          unit: metric_unit
        }
      ]
    )
  end
end
