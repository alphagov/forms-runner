namespace :jobs do
  desc "Retry failed"
  task :retry_failed, %i[job_id] => :environment do |_, args|
    job_id = args[:job_id]

    usage_message = "usage: rake jobs:retry_failed[<job_id>]"
    abort usage_message if job_id.blank?

    job = find_job!(job_id)
    failed_execution = find_failed_execution!(job)

    failed_execution.retry

    Rails.logger.info "Scheduled retry for job with ID: #{job_id}, class: #{job.class_name}"
  end

  desc "Delete failed execution for the given job IDs. Only use this if you're sure the jobs don't need to be retried."
  task :delete_failed, [] => :environment do |_, args|
    job_ids = args.to_a

    usage_message = "usage: rake jobs:delete_failed[<job_id>, ...]"
    abort usage_message if job_ids.blank?

    job_ids.each do |job_id|
      job = find_job!(job_id)
      failed_execution = find_failed_execution!(job)

      failed_execution.destroy!

      Rails.logger.info "Deleted failed execution for job with ID: #{job_id}, class: #{job.class_name}."
    end
  end

  desc "Retry all failed jobs for a given job class"
  task :retry_all_failed, [:job_class_name] => :environment do |_, args|
    job_class_name = args[:job_class_name]

    usage_message = "usage: rake jobs:retry_all_failed[<job_class_name>]"
    abort usage_message if job_class_name.blank?

    failed_jobs = SolidQueue::Job.joins(:failed_execution).where(class_name: job_class_name)

    Rails.logger.info "Found #{failed_jobs.length} failed #{job_class_name} jobs to retry"

    SolidQueue::FailedExecution.retry_all(failed_jobs)

    Rails.logger.info "Retried #{failed_jobs.length} failed #{job_class_name} jobs"
  end

  desc "List failed jobs for the given queue"
  task :list_failed, [:queue_name] => :environment do |_, args|
    queue_name = args[:queue_name]

    usage_message = "usage: rake jobs:list_failed[<queue_name>]"
    abort usage_message if queue_name.blank?

    failed_executions = SolidQueue::FailedExecution.joins(:job).where(solid_queue_jobs: { queue_name: queue_name })

    Rails.logger.info "Found #{failed_executions.length} failed jobs on #{queue_name} queue"

    failed_executions.each do |failed_execution|
      job = failed_execution.job
      Rails.logger.info "Failed execution - Job ID: #{job.active_job_id}, Job Class: #{job.class_name}, Failed At: #{failed_execution.created_at}, Error Message: #{failed_execution.error.to_s.truncate(500)}"
    end
  end
end

def find_job!(job_id)
  job = SolidQueue::Job.where(active_job_id: job_id).last
  abort "Job with job_id #{job_id} not found" unless job
  job
end

def find_failed_execution!(job)
  failed_execution = SolidQueue::FailedExecution.find_by(job_id: job.id)
  abort "Job with job_id #{job.active_job_id} is not failed" unless failed_execution
  failed_execution
end
