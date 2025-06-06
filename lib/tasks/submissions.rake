namespace :submissions do
  desc "Check submission statuses"
  task check_submission_statuses: :environment do
    Rails.logger.info "#{Submission.pending.count} pending submissions"
    Rails.logger.info "#{Submission.bounced.count} bounced submissions"
  end

  desc "Retry bounced submissions"
  task :retry_bounced_submissions, %i[form_id] => :environment do |_, args|
    form_id = args[:form_id]

    usage_message = "usage: rake submissions:retry_bounced_submissions[<form_id>]".freeze
    abort usage_message if form_id.blank?

    submissions_to_retry = Submission.where(form_id: form_id)
                                     .bounced

    Rails.logger.info "#{submissions_to_retry.length} submissions to retry for form with ID: #{form_id}"

    submissions_to_retry.each do |submission|
      Rails.logger.info "Retrying submission with reference #{submission.reference} for form with ID: #{form_id}"
      SendSubmissionJob.perform_later(submission)
    end
  end

  desc "Disregard bounced submission"
  task :disregard_bounced_submission, %i[reference] => :environment do |_, args|
    reference = args[:reference]

    usage_message = "usage: rake submissions:disregard_bounced_submission[<reference>]".freeze
    abort usage_message if reference.blank?

    disregard_bounced_submission(reference)
  end

  desc "Retry failed send submission job"
  task :retry_failed_send_job, %i[job_id] => :environment do |_, args|
    job_id = args[:job_id]

    usage_message = "usage: rake submissions:retry_failed_send_job[<job_id>]"
    abort usage_message if job_id.blank?

    job = SolidQueue::Job.find_by(active_job_id: job_id)

    abort "Job with job_id #{job_id} not found" unless job

    failed_execution = SolidQueue::FailedExecution.find_by(job_id: job.id)

    abort "Job with job_id #{job_id} is not failed" unless failed_execution

    failed_execution.retry

    Rails.logger.info "Scheduled retry for submission job with ID: #{job_id}"
  end

  desc "Retry all failed send submission jobs"
  task retry_all_failed_send_jobs: :environment do |_, _args|
    failed_jobs = SolidQueue::Job.joins(:failed_execution).where(class_name: SendSubmissionJob.name)

    Rails.logger.info "Found #{failed_jobs.length} failed submission jobs to retry"

    SolidQueue::FailedExecution.retry_all(failed_jobs)

    Rails.logger.info "Retried #{failed_jobs.length} failed submission jobs"
  end
end

def disregard_bounced_submission(reference)
  submission = Submission.find_by(reference:)

  if submission.blank?
    Rails.logger.info "No submission found with reference #{reference}"
    return
  end

  unless submission.bounced?
    Rails.logger.info "Submission with reference #{reference} hasn't bounced"
    return
  end

  Rails.logger.info "Disregarding bounce of submission with reference #{submission.reference}"
  submission.pending!
end
