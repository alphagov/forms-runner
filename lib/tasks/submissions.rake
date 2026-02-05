namespace :submissions do
  desc "Check delivery statuses"
  task check_delivery_statuses: :environment do
    Rails.logger.info "#{Delivery.pending.count} pending deliveries"
    Rails.logger.info "#{Delivery.failed.count} failed deliveries"
  end

  desc "List all bounced submission deliveries for the given form ID"
  task :list_bounced_submissions_for_form, %i[form_id] => :environment do |_t, args|
    form_id = args[:form_id]

    usage_message = "usage: rake submissions:list_bounced_submissions_for_form[<form_id>]".freeze
    abort usage_message if form_id.blank?

    deliveries = Delivery.failed.joins(:submissions).where(submissions: { form_id: form_id }).distinct
    Rails.logger.info "Found #{deliveries.length} bounced submission deliveries for form with ID #{form_id}"
    deliveries.find_each do |delivery|
      # This will need to be updated when we support batches
      submission = delivery.submissions.first
      Rails.logger.info "Submission reference: #{submission.reference}, created_at: #{submission.created_at}, last_attempt_at: #{delivery.last_attempt_at}"
    end
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

  desc "Retry bounced deliveries"
  task :retry_bounced_deliveries, %i[form_id] => :environment do |_, args|
    form_id = args[:form_id]

    usage_message = "usage: rake submissions:retry_bounced_deliveries[<form_id>]".freeze
    abort usage_message if form_id.blank?

    bounced_deliveries = Delivery.failed.joins(:submissions).where(submissions: { form_id: form_id }).distinct

    Rails.logger.info "#{bounced_deliveries.length} submission deliveries to retry for form with ID: #{form_id}"

    bounced_deliveries.each do |delivery|
      # This will need to be updated when we support batches
      submission = delivery.submissions.first
      Rails.logger.info "Retrying submission with reference #{submission.reference} for form with ID: #{form_id}"
      SendSubmissionJob.perform_later(submission)
    end
  end

  desc "Disregard bounced delivery"
  task :disregard_bounced_delivery, %i[delivery_reference] => :environment do |_, args|
    delivery_reference = args[:delivery_reference]

    usage_message = "usage: rake submissions:disregard_bounced_delivery[<delivery_reference>]".freeze
    abort usage_message if delivery_reference.blank?

    delivery = Delivery.find_by(delivery_reference: delivery_reference)

    if delivery.blank?
      Rails.logger.info "No delivery found with delivery_reference #{delivery_reference}"
      next
    end

    unless delivery.failed?
      Rails.logger.info "Delivery with delivery_reference #{delivery_reference} hasn't bounced"
      next
    end

    delivery.update!(failed_at: nil, failure_reason: nil)
    Rails.logger.info "Disregarded bounce of delivery with delivery_reference #{delivery_reference}"
  end

  desc "Disregard bounced deliveries created between two timestamps for a specific form"
  task :disregard_bounced_deliveries_for_form, %i[form_id start_timestamp end_timestamp dry_run] => :environment do |_, args|
    form_id = args[:form_id]
    start_timestamp = args[:start_timestamp]
    end_timestamp = args[:end_timestamp]
    dry_run_arg = args[:dry_run]
    dry_run = dry_run_arg == "true"

    usage_message = "usage: rake submissions:disregard_bounced_deliveries_for_form[<form_id>, <start_timestamp>, <end_timestamp>, <dry_run>]".freeze
    if form_id.blank? || start_timestamp.blank? || end_timestamp.blank? || !dry_run_arg.in?(%w[true false])
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

    Rails.logger.info "Dry run mode: #{dry_run ? 'enabled' : 'disabled'}"

    deliveries = Delivery.failed
                         .joins(:submissions)
                         .where(submissions: { form_id: form_id })
                         .where(created_at: start_time..end_time)
                         .distinct

    Rails.logger.info "Found #{deliveries.length} bounced submission deliveries to disregard for form ID #{form_id} in time range: #{start_time} to #{end_time}"

    deliveries.each do |delivery|
      if dry_run
        Rails.logger.info "Would disregard bounce of delivery with delivery_reference #{delivery.delivery_reference} which was created at #{delivery.created_at}"
      else
        delivery.update!(failed_at: nil, failure_reason: nil)
        Rails.logger.info "Disregarded bounce of delivery with delivery_reference #{delivery.delivery_reference}"
      end
    end
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
    dry_run_arg = args[:dry_run]
    dry_run = dry_run_arg == "true"

    usage_message = "usage: rake submissions:redeliver_submissions_by_date[<form_id>,<start_timestamp>,<end_timestamp>,<dry_run>]".freeze

    if form_id.blank? || start_timestamp.blank? || end_timestamp.blank? || !dry_run_arg.in?(%w[true false])
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

  namespace :file_answers do
    desc "Generate email filename for file upload answers that do not have an original filename stored and schedule the submission to be sent"
    task :fix_missing_original_filenames, %i[reference] => :environment do |_, args|
      submission = Submission.find_by(reference: args.reference)
      abort "No submission found with reference #{args.reference}" if submission.blank?

      submission.answers.each_pair do |question_id, answer|
        next unless answer.include?("original_filename") && answer["original_filename"].blank? && answer["uploaded_file_key"].present?

        question = submission.form.page_by_id(question_id)
        extension = ::File.extname(answer["uploaded_file_key"])
        filename = "#{question.position}-#{question.question_text.parameterize}#{extension}"
        filename = FileUploadFilenameGenerator.to_email_attachment(filename, submission_reference: submission.reference, suffix: answer["filename_suffix"])
        answer["email_filename"] = filename
      end

      submission.save!

      if submission.answers_previously_changed?
        Rails.logger.info "Re-delivering submission with reference #{submission.reference}"
        SendSubmissionJob.perform_later(submission)
      end
    end
  end
end
