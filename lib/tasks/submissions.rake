namespace :submissions do
  desc "Check submission statuses"
  task check_submission_statuses: :environment do
    Rails.logger.info "#{Submission.pending.count} pending submissions"
    Rails.logger.info "#{Submission.bounced.count} bounced submissions"
  end

  desc "Fetch and display all data for a specific submission given a reference"
  task :inspect_submission_data, [:reference] => :environment do |_t, args|
    submission = Submission.find_by(reference: args.reference)
    if submission.nil?
      puts "Submission with reference #{args.reference} not found."
    else
      puts "Data for submission with reference #{args.reference}:"
      pp submission.answers
      pp submission
    end
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

    job = SolidQueue::Job.where(active_job_id: job_id).last

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

  desc "Re-deliver submissions created between two timestamps for a specific form"
  task :redeliver_submissions_by_date, %i[form_id start_timestamp end_timestamp dry_run] => :environment do |_, args|
    form_id = args[:form_id]
    start_timestamp = args[:start_timestamp]
    end_timestamp = args[:end_timestamp]
    dry_run = args[:dry_run] == "true"

    usage_message = "usage: rake submissions:redeliver_submissions_by_date[<form_id>,<start_timestamp>,<end_timestamp>,<dry_run>]".freeze

    if form_id.blank? || start_timestamp.blank? || end_timestamp.blank?
      abort usage_message
    end

    start_time = Time.zone.parse(start_timestamp)
    end_time = Time.zone.parse(end_timestamp)

    if start_time.nil? || end_time.nil?
      abort "Error: Invalid timestamp format. Use ISO 8601 format (e.g. '2024-01-01T00:00:00Z')"
    end

    if start_time >= end_time
      abort "Error: Start timestamp must be before end timestamp"
    end

    submissions_to_redeliver = Submission.where(form_id: form_id)
                                        .where(created_at: start_time..end_time)

    Rails.logger.info "Time range: #{start_time} to #{end_time}"
    Rails.logger.info "Dry run mode: #{dry_run ? 'enabled' : 'disabled'}"

    if submissions_to_redeliver.any?
      Rails.logger.info "Found #{submissions_to_redeliver.count} submissions to re-deliver for form ID: #{form_id}"

      submissions_to_redeliver.each do |submission|
        if dry_run
          Rails.logger.info "Would re-deliver submission with reference #{submission.reference}"
        else
          Rails.logger.info "Re-delivering submission with reference #{submission.reference}"
          SendSubmissionJob.perform_later(submission)
        end
      end
    else
      Rails.logger.info "No submissions found matching the criteria"
    end
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
