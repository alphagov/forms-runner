class CloudWatchService
  REGION = "eu-west-2".freeze
  FORM_METRICS_NAMESPACE = "Forms".freeze
  JOBS_METRICS_NAMESPACE = "Forms/Jobs".freeze
  SERVICE_NAME = "forms-runner".freeze

  def self.record_form_submission_metric(form_id:)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: FORM_METRICS_NAMESPACE,
      metric_data: [
        {
          metric_name: "Submitted",
          dimensions: [
            environment_dimension,
            form_id_dimension(form_id),
          ],
          value: 1,
          unit: "Count",
        },
      ],
    )
  end

  def self.record_form_start_metric(form_id:)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: FORM_METRICS_NAMESPACE,
      metric_data: [
        {
          metric_name: "Started",
          dimensions: [
            environment_dimension,
            form_id_dimension(form_id),
          ],
          value: 1,
          unit: "Count",
        },
      ],
    )
  end

  def self.record_submission_sent_metric(milliseconds_since_scheduled)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: JOBS_METRICS_NAMESPACE,
      metric_data: [
        {
          metric_name: "TimeToSendSubmission",
          dimensions: [
            environment_dimension,
            service_name_dimension,
            job_dimension(SendSubmissionJob.name),
          ],
          value: milliseconds_since_scheduled,
          unit: "Milliseconds",
        },
      ],
    )
  end

  def self.record_submission_delivery_latency_metric(milliseconds_since_scheduled, delivery_method)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: FORM_METRICS_NAMESPACE,
      metric_data: [
        {
          metric_name: "SubmissionDeliveryLatency",
          dimensions: [
            environment_dimension,
            {
              name: "SubmissionDeliveryMethod",
              value: delivery_method,
            },
          ],
          value: milliseconds_since_scheduled,
          unit: "Milliseconds",
        },
      ],
    )
  end

  def self.record_job_failure_metric(job_name)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: JOBS_METRICS_NAMESPACE,
      metric_data: [
        {
          metric_name: "Failure",
          dimensions: [
            environment_dimension,
            service_name_dimension,
            job_dimension(job_name),
          ],
          value: 1,
          unit: "Count",
        },
      ],
    )
  end

  def self.record_job_started_metric(job_name)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: JOBS_METRICS_NAMESPACE,
      metric_data: [
        {
          metric_name: "Started",
          dimensions: [
            environment_dimension,
            service_name_dimension,
            job_dimension(job_name),
          ],
          value: 1,
          unit: "Count",
        },
      ],
    )
  end

  def self.record_queue_length_metric(queue_name, length)
    return unless Settings.cloudwatch_metrics_enabled

    cloudwatch_client.put_metric_data(
      namespace: JOBS_METRICS_NAMESPACE,
      metric_data: [
        {
          metric_name: "QueueLength",
          dimensions: [
            environment_dimension,
            service_name_dimension,
            queue_name_dimension(queue_name),
          ],
          value: length,
          unit: "Count",
        },
      ],
    )
  end

  def self.environment_dimension
    {
      name: "Environment",
      value: Settings.forms_env.downcase,
    }
  end

  def self.form_id_dimension(form_id)
    {
      name: "FormId",
      value: form_id.to_s,
    }
  end

  def self.service_name_dimension
    {
      name: "ServiceName",
      value: SERVICE_NAME,
    }
  end

  def self.job_dimension(job_name)
    {
      name: "JobName",
      value: job_name,
    }
  end

  def self.queue_name_dimension(queue_name)
    {
      name: "QueueName",
      value: queue_name,
    }
  end

  def self.cloudwatch_client
    Aws::CloudWatch::Client.new(region: REGION)
  end
end
