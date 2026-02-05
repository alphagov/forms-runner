require "rake"
require "rails_helper"

RSpec.describe "submissions.rake" do
  include ActiveJob::TestHelper

  before do
    Rake.application.rake_require "tasks/submissions"
    Rake::Task.define_task(:environment)
  end

  describe "submissions:inspect_submission_data" do
    subject(:task) do
      Rake::Task["submissions:inspect_submission_data"]
        .tap(&:reenable)
    end

    before do
      create :submission, :sent, delivery_status: :pending, reference: "test_ref"
    end

    it "displays submission data when found" do
      expect { task.invoke("test_ref") }.to output(a_string_including('reference: "test_ref"')).to_stdout
    end

    it "displays an error message when submission is not found" do
      expect { task.invoke("non_existent_ref") }.to output("Submission with reference non_existent_ref not found.\n").to_stdout
    end

    it "displays the answers submitted by the user" do
      expect { task.invoke("test_ref") }.to output(a_string_including("Option 1")).to_stdout
    end
  end

  describe "submissions:check_submission_statuses" do
    subject(:task) do
      Rake::Task["submissions:check_submission_statuses"]
        .tap(&:reenable)
    end

    before do
      create :submission,
             :sent,
             delivery_status: :pending

      create_list :submission, 2,
                  :sent,
                  delivery_status: :bounced
    end

    it "logs how many submissions there are for each mail status" do
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).with("1 pending submissions")
      expect(Rails.logger).to receive(:info).with("2 bounced submissions")

      task.invoke
    end
  end

  describe "submissions:list_bounced_submissions_for_form" do
    subject(:task) do
      Rake::Task["submissions:list_bounced_submissions_for_form"]
        .tap(&:reenable)
    end

    let(:form_id) { 42 }

    let!(:bounced_submission) { create :submission, :bounced, form_id: }
    let!(:another_bounced_submission) { create :submission, :bounced, form_id: }

    before do
      # create some submissions that won't be matched
      create(:submission, form_id:)
      create(:submission, :bounced, form_id: 99)
    end

    it "logs the bounced submissions" do
      expect(Rails.logger).to receive(:info).with("Found 2 bounced submission deliveries for form with ID #{form_id}")
      expect(Rails.logger).to receive(:info).with "Submission reference: #{bounced_submission.reference}, created_at: #{bounced_submission.created_at}, last_attempt_at: #{bounced_submission.single_submission_delivery.last_attempt_at}"
      expect(Rails.logger).to receive(:info).with "Submission reference: #{another_bounced_submission.reference}, created_at: #{another_bounced_submission.created_at}, last_attempt_at: #{another_bounced_submission.single_submission_delivery.last_attempt_at}"
      task.invoke(form_id)
    end
  end

  describe "submissions:retry_bounced_deliveries" do
    subject(:task) do
      Rake::Task["submissions:retry_bounced_deliveries"]
        .tap(&:reenable)
    end

    let(:form_id) { 1 }
    let(:other_form_id) { 2 }
    let!(:bounced_submission) { create :submission, :bounced, form_id: }
    let!(:pending_submission) { create :submission, :sent, form_id: }

    before do
      create :submission, :sent, form_id: other_form_id
    end

    context "with valid arguments" do
      let(:valid_args) { [form_id] }

      it "logs how many deliveries to retry" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with("1 submission deliveries to retry for form with ID: #{form_id}")

        task.invoke(*valid_args)
      end

      context "with a form ID with bounced deliveries" do
        it "logs submissions that are being retried" do
          allow(Rails.logger).to receive(:info)
          expect(Rails.logger).to receive(:info).with("Retrying submission with reference #{bounced_submission.reference} for form with ID: #{form_id}")

          task.invoke(*valid_args)
        end

        it "enqueues bounced submissions for retrying" do
          expect {
            task.invoke(*valid_args)
          }.to have_enqueued_job.with(bounced_submission)
        end

        it "does not enqueue pending submissions for retrying" do
          expect {
            task.invoke(*valid_args)
          }.not_to have_enqueued_job.with(pending_submission)
        end
      end

      context "with a form ID without bounced submissions" do
        let(:valid_args) { [other_form_id] }

        it "does not enqueue pending submissions for retrying" do
          expect {
            task.invoke(*valid_args)
          }.not_to have_enqueued_job
        end
      end
    end

    context "with invalid arguments" do
      let(:invalid_args) { [] }

      it "aborts with a usage message" do
        expect {
          task.invoke(*invalid_args)
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:retry_bounced_deliveries[<form_id>]\n").to_stderr
      end
    end
  end

  describe "submissions:disregard_bounced_delivery" do
    subject(:task) do
      Rake::Task["submissions:disregard_bounced_delivery"]
        .tap(&:reenable)
    end

    let(:delivery_reference) { "delivery-reference" }
    let(:args) { [delivery_reference] }
    let(:form_id) { 1 }
    let!(:submission) { create :submission, :bounced, form_id:, reference: "submission-reference" }
    let!(:delivery) { create :delivery, :failed, submissions: [submission], delivery_reference: delivery_reference }

    context "with valid arguments" do
      context "when the delivery is bounced" do
        it "logs delivery bounce has been disregarded" do
          allow(Rails.logger).to receive(:info)
          expect(Rails.logger).to receive(:info).with("Disregarded bounce of delivery with delivery_reference #{delivery_reference}")

          task.invoke(*args)
        end

        it "clears the bounced status" do
          task.invoke(*args)
          delivery.reload
          expect(delivery.failed_at).to be_nil
          expect(delivery.failure_reason).to be_nil
          expect(delivery.reload.pending?).to be true
        end
      end

      context "when the delivery has both delivered_at and failed_at set and is considered bounced" do
        let!(:delivery) { create :delivery, :failed_after_delivery, submissions: [submission], delivery_reference: delivery_reference }

        it "clears the bounced status" do
          task.invoke(*args)
          delivery.reload
          expect(delivery.failed_at).to be_nil
          expect(delivery.failure_reason).to be_nil
          expect(delivery.delivered_at).not_to be_nil
          expect(delivery.reload.delivered?).to be true
        end
      end

      context "when no delivery exists with that delivery_reference" do
        let(:args) { ["non-existent reference"] }

        it "logs that there is no delivery" do
          allow(Rails.logger).to receive(:info)
          expect(Rails.logger).to receive(:info).with("No delivery found with delivery_reference non-existent reference")

          task.invoke(*args)
        end
      end

      context "when the delivery has not bounced" do
        let!(:delivery) { create :delivery, submissions: [submission], delivery_reference: delivery_reference }

        it "logs that the delivery hasn't bounced" do
          allow(Rails.logger).to receive(:info)
          expect(Rails.logger).to receive(:info).with("Delivery with delivery_reference #{delivery_reference} hasn't bounced")

          task.invoke(*args)
        end

        it "does not update the delivery" do
          expect {
            task.invoke(*args)
          }.not_to(change { delivery.reload.attributes })
        end
      end
    end

    context "with invalid arguments" do
      let(:invalid_args) { [] }

      it "aborts with a usage message" do
        expect {
          task.invoke(*invalid_args)
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:disregard_bounced_delivery[<delivery_reference>]\n").to_stderr
      end
    end
  end

  describe "submissions:disregard_bounced_deliveries_for_form" do
    subject(:task) do
      Rake::Task["submissions:disregard_bounced_deliveries_for_form"]
        .tap(&:reenable)
    end

    let(:form_id) { 1 }
    let(:other_form_id) { 2 }
    let(:start_time) { "2024-01-01T00:00:00Z" }
    let(:end_time) { "2024-01-02T00:00:00Z" }
    let(:dry_run) { "false" }

    let!(:early_matching_delivery) do
      submission = create(:submission, form_id:)
      create :delivery, :failed, submissions: [submission], created_at: Time.parse("2024-01-01T12:00:00Z")
    end

    let!(:late_matching_delivery) do
      submission = create(:submission, form_id:)
      create :delivery, :failed, submissions: [submission], created_at: Time.parse("2024-01-01T18:00:00Z")
    end

    let!(:not_bounced_delivery) do
      submission = create(:submission, form_id:)
      create :delivery, submissions: [submission], created_at: Time.parse("2024-01-01T12:00:00Z")
    end

    let!(:non_matching_delivery_different_form) do
      submission = create(:submission, form_id: other_form_id)
      create :delivery, :failed, submissions: [submission], created_at: Time.parse("2024-01-01T12:00:00Z")
    end

    let!(:non_matching_delivery_different_time) do
      submission = create(:submission, form_id:)
      create :delivery, :failed, submissions: [submission], created_at: Time.parse("2023-12-31T23:59:59Z")
    end

    context "with valid arguments" do
      let(:valid_args) { [form_id, start_time, end_time, dry_run] }

      it "clears failed_at and failure_reason for matched deliveries" do
        expect {
          task.invoke(*valid_args)
        }.to change { early_matching_delivery.reload.failed_at }.to(nil)
               .and change { early_matching_delivery.reload.failure_reason }.to(nil)
               .and change { late_matching_delivery.reload.failed_at }.to(nil)
               .and change { late_matching_delivery.reload.failure_reason }.to(nil)
      end

      it "does not update non-matching deliveries or submissions" do
        expect {
          task.invoke(*valid_args)
        }.to not_change { not_bounced_delivery.reload.attributes }
               .and not_change { non_matching_delivery_different_form.reload.failed_at }
               .and(not_change { non_matching_delivery_different_time.reload.failed_at })
      end

      it "logs the deliveries to disregard" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with("Found 2 bounced submission deliveries to disregard for form ID #{form_id} in time range: #{Time.zone.parse(start_time)} to #{Time.zone.parse(end_time)}").once
        expect(Rails.logger).to receive(:info).with("Disregarded bounce of delivery with delivery_reference #{early_matching_delivery.delivery_reference}")
        expect(Rails.logger).to receive(:info).with("Disregarded bounce of delivery with delivery_reference #{late_matching_delivery.delivery_reference}")
        task.invoke(*valid_args)
      end

      context "when dry_run is true" do
        let(:dry_run) { "true" }

        it "does not update any deliveries" do
          expect {
            task.invoke(*valid_args)
          }.not_to(change { early_matching_delivery.reload.failed_at })
        end

        it "logs the deliveries that would be disregarded" do
          allow(Rails.logger).to receive(:info)
          expect(Rails.logger).to receive(:info).with("Would disregard bounce of delivery with delivery_reference #{early_matching_delivery.delivery_reference} which was created at #{early_matching_delivery.created_at}")
          expect(Rails.logger).to receive(:info).with("Would disregard bounce of delivery with delivery_reference #{late_matching_delivery.delivery_reference} which was created at #{late_matching_delivery.created_at}")
          task.invoke(*valid_args)
        end
      end
    end

    context "with invalid arguments" do
      it "aborts when form_id is missing" do
        expect {
          task.invoke("", start_time, end_time, dry_run)
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:disregard_bounced_deliveries_for_form[<form_id>, <start_timestamp>, <end_timestamp>, <dry_run>]\n").to_stderr
      end

      it "aborts when start_timestamp is missing" do
        expect {
          task.invoke(form_id, "", end_time, dry_run)
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:disregard_bounced_deliveries_for_form[<form_id>, <start_timestamp>, <end_timestamp>, <dry_run>]\n").to_stderr
      end

      it "aborts when end_timestamp is missing" do
        expect {
          task.invoke(form_id, start_time, "", dry_run)
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:disregard_bounced_deliveries_for_form[<form_id>, <start_timestamp>, <end_timestamp>, <dry_run>]\n").to_stderr
      end

      it "aborts when start_timestamp is invalid" do
        expect {
          task.invoke(form_id, "invalid-date", end_time, dry_run)
        }.to raise_error(SystemExit)
               .and output("Error: Invalid timestamp format. Use ISO 8601 format (e.g. '2024-01-01T00:00:00Z')\n").to_stderr
      end

      it "aborts when end_timestamp is invalid" do
        expect {
          task.invoke(form_id, start_time, "invalid-date", dry_run)
        }.to raise_error(SystemExit)
               .and output("Error: Invalid timestamp format. Use ISO 8601 format (e.g. '2024-01-01T00:00:00Z')\n").to_stderr
      end

      it "aborts when start_timestamp is after end_timestamp" do
        expect {
          task.invoke(form_id, "2024-01-02T00:00:00Z", "2024-01-01T00:00:00Z", dry_run)
        }.to raise_error(SystemExit)
               .and output("Error: Start timestamp must be before end timestamp\n").to_stderr
      end

      it "aborts when start_timestamp equals end_timestamp" do
        expect {
          task.invoke(form_id, start_time, start_time, dry_run)
        }.to raise_error(SystemExit)
               .and output("Error: Start timestamp must be before end timestamp\n").to_stderr
      end

      it "aborts when dry_run is an invalid value" do
        expect {
          task.invoke(form_id, start_time, start_time, "foo")
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:disregard_bounced_deliveries_for_form[<form_id>, <start_timestamp>, <end_timestamp>, <dry_run>]\n").to_stderr
      end
    end
  end

  describe "submissions:retry_failed_send_job" do
    subject(:task) do
      Rake::Task["submissions:retry_failed_send_job"]
        .tap(&:reenable)
    end

    # If a job is retried, there are multiple jobs with the same active_job_id but the failed execution is only
    # attached to the final one. Create another job with the same active_job_id first to simulate this.
    let(:first_job) { create :solid_queue_job }
    let(:job) { create :solid_queue_job, active_job_id: first_job.active_job_id }

    context "with valid arguments" do
      let(:valid_args) { [job.active_job_id] }

      context "when the job is failed" do
        before do
          create :solid_queue_failed_execution, job: job
        end

        it "calls retry for the failed execution" do
          # rubocop:disable RSpec/AnyInstance
          expect_any_instance_of(SolidQueue::FailedExecution).to receive(:retry).once
          # rubocop:enable RSpec/AnyInstance

          task.invoke(*valid_args)
        end

        it "logs that the job was scheduled for retry" do
          expect(Rails.logger).to receive(:info).with("Scheduled retry for submission job with ID: #{job.active_job_id}")

          task.invoke(*valid_args)
        end
      end

      context "when the job is not failed" do
        it "aborts with message that the job id not failed" do
          expect {
            task.invoke(*valid_args)
          }.to raise_error(SystemExit)
                 .and output("Job with job_id #{job.active_job_id} is not failed\n").to_stderr
        end
      end

      context "when the job does not exist" do
        it "aborts with message that the job was not found" do
          expect {
            task.invoke("foo")
          }.to raise_error(SystemExit)
                 .and output("Job with job_id foo not found\n").to_stderr
        end
      end
    end

    context "with invalid arguments" do
      it "aborts with a usage message" do
        expect {
          task.invoke
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:retry_failed_send_job[<job_id>]\n").to_stderr
      end
    end
  end

  describe "submissions:retry_all_failed_send_jobs" do
    subject(:task) do
      Rake::Task["submissions:retry_all_failed_send_jobs"]
        .tap(&:reenable)
    end

    let(:failed_job) { create :solid_queue_job }
    let(:other_failed_job) { create :solid_queue_job }
    let(:failed_not_submission_job) { create :solid_queue_job, class_name: "SomethingElse" }
    let(:not_failed_job) { create :solid_queue_job }

    before do
      create :solid_queue_failed_execution, job: failed_job
      create :solid_queue_failed_execution, job: other_failed_job
      create :solid_queue_failed_execution, job: failed_not_submission_job
    end

    it "retries the failed submission jobs" do
      expect(SolidQueue::FailedExecution).to receive(:retry_all).with([failed_job, other_failed_job])
      task.invoke
    end

    it "logs that 2 jobs were retried" do
      expect(Rails.logger).to receive(:info).with("Found 2 failed submission jobs to retry")
      expect(Rails.logger).to receive(:info).with("Retried 2 failed submission jobs")
      task.invoke
    end
  end

  describe "submissions:redeliver_submissions_by_date" do
    subject(:task) do
      Rake::Task["submissions:redeliver_submissions_by_date"]
        .tap(&:reenable)
    end

    let(:form_id) { 1 }
    let(:other_form_id) { 2 }
    let(:start_time) { "2024-01-01T00:00:00Z" }
    let(:end_time) { "2024-01-02T00:00:00Z" }
    let(:dry_run) { "false" }

    let!(:early_matching_submission) do
      create :submission,
             :sent,
             form_id:,
             created_at: Time.parse("2024-01-01T12:00:00Z"),
             reference: "ref1"
    end

    let!(:late_matching_submission) do
      create :submission,
             :sent,
             form_id:,
             created_at: Time.parse("2024-01-01T18:00:00Z"),
             reference: "ref2"
    end

    let!(:non_matching_submission_different_form) do
      create :submission,
             :sent,
             form_id: other_form_id,
             created_at: Time.parse("2024-01-01T12:00:00Z"),
             reference: "ref3"
    end

    let!(:non_matching_submission_different_time) do
      create :submission,
             :sent,
             form_id:,
             created_at: Time.parse("2023-12-31T23:59:59Z"),
             reference: "ref4"
    end

    context "with valid arguments" do
      let(:valid_args) { [form_id, start_time, end_time, dry_run] }

      it "enqueues matching submissions for re-delivery" do
        expect {
          task.invoke(*valid_args)
        }.to have_enqueued_job(SendSubmissionJob).with(early_matching_submission)
                                                 .and have_enqueued_job(SendSubmissionJob).with(late_matching_submission)
      end

      it "does not enqueue non-matching submissions" do
        expect {
          task.invoke(*valid_args)
        }.not_to have_enqueued_job(SendSubmissionJob).with(non_matching_submission_different_form)

        expect {
          task.invoke(*valid_args)
        }.not_to have_enqueued_job(SendSubmissionJob).with(non_matching_submission_different_time)
      end

      context "when dry_run is true" do
        let(:dry_run) { "true" }

        it "does not enqueue any jobs" do
          expect {
            task.invoke(*valid_args)
          }.not_to have_enqueued_job(SendSubmissionJob)
        end
      end

      context "when no submissions match the criteria" do
        let(:valid_args) { [form_id, "2025-01-01T00:00:00Z", "2025-01-02T00:00:00Z", dry_run] }

        it "does not enqueue any jobs" do
          expect {
            task.invoke(*valid_args)
          }.not_to have_enqueued_job(SendSubmissionJob)
        end
      end
    end

    context "with invalid arguments" do
      it "aborts when form_id is missing" do
        expect {
          task.invoke("", start_time, end_time, dry_run)
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:redeliver_submissions_by_date[<form_id>,<start_timestamp>,<end_timestamp>,<dry_run>]\n").to_stderr
      end

      it "aborts when start_timestamp is missing" do
        expect {
          task.invoke(form_id, "", end_time, dry_run)
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:redeliver_submissions_by_date[<form_id>,<start_timestamp>,<end_timestamp>,<dry_run>]\n").to_stderr
      end

      it "aborts when end_timestamp is missing" do
        expect {
          task.invoke(form_id, start_time, "", dry_run)
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:redeliver_submissions_by_date[<form_id>,<start_timestamp>,<end_timestamp>,<dry_run>]\n").to_stderr
      end

      it "aborts when start_timestamp is invalid" do
        expect {
          task.invoke(form_id, "invalid-date", end_time, dry_run)
        }.to raise_error(SystemExit)
               .and output("Error: Invalid timestamp format. Use ISO 8601 format (e.g. '2024-01-01T00:00:00Z')\n").to_stderr
      end

      it "aborts when end_timestamp is invalid" do
        expect {
          task.invoke(form_id, start_time, "invalid-date", dry_run)
        }.to raise_error(SystemExit)
               .and output("Error: Invalid timestamp format. Use ISO 8601 format (e.g. '2024-01-01T00:00:00Z')\n").to_stderr
      end

      it "aborts when start_timestamp is after end_timestamp" do
        expect {
          task.invoke(form_id, "2024-01-02T00:00:00Z", "2024-01-01T00:00:00Z", dry_run)
        }.to raise_error(SystemExit)
               .and output("Error: Start timestamp must be before end timestamp\n").to_stderr
      end

      it "aborts when start_timestamp equals end_timestamp" do
        expect {
          task.invoke(form_id, start_time, start_time, dry_run)
        }.to raise_error(SystemExit)
               .and output("Error: Start timestamp must be before end timestamp\n").to_stderr
      end

      it "aborts when dry_run is an invalid value" do
        expect {
          task.invoke(form_id, start_time, start_time, "foo")
        }.to raise_error(SystemExit)
               .and output("usage: rake submissions:redeliver_submissions_by_date[<form_id>,<start_timestamp>,<end_timestamp>,<dry_run>]\n").to_stderr
      end
    end
  end

  describe "submissions:file_answers:fix_missing_original_filenames" do
    subject(:task) do
      Rake::Task["submissions:file_answers:fix_missing_original_filenames"]
        .tap(&:reenable)
    end

    let(:submission) do
      create(:submission, form_document:, answers:, reference: "F008AR")
    end

    let(:form_document) do
      build(
        :v2_form_document,
        steps: [
          build(
            :v2_question_page_step,
            id: 100,
            answer_type: "file",
            question_text: "Upload your evidence",
            position: "1",
          ),
        ],
      )
    end

    context "when original filename is missing" do
      let(:answers) do
        {
          "100" => {
            "file" => nil,
            "original_filename" => "",
            "uploaded_file_key" => "#{Faker::Internet.uuid}.jpg",
            "filename_suffix" => "",
            "email_filename" => "",
          },
        }
      end

      it "sets the email filename to the question text" do
        task.invoke(submission.reference)
        submission.reload
        expect(submission.answers["100"]).to include(
          "original_filename" => "",
          "email_filename" => "1-upload-your-evidence_F008AR.jpg",
        )
      end

      it "reschedules the submission" do
        task.invoke(submission.reference)
        expect(SendSubmissionJob).to have_been_enqueued
      end
    end

    context "when original filename is present" do
      let(:answers) do
        {
          "100" => {
            "file" => nil,
            "original_filename" => "my-test-picture.jpg",
            "uploaded_file_key" => "#{Faker::Internet.uuid}.jpg",
            "filename_suffix" => "",
            "email_filename" => "",
          },
        }
      end

      it "does not set the email filename" do
        task.invoke(submission.reference)
        submission.reload
        expect(submission.answers["100"]).to include(
          "original_filename" => "my-test-picture.jpg",
          "email_filename" => "",
        )
      end

      it "does not reschedule the submission" do
        task.invoke(submission.reference)
        expect(SendSubmissionJob).not_to have_been_enqueued
      end
    end

    context "when there is an optional file question" do
      let(:form_document) do
        build(
          :v2_form_document,
          steps: [
            build(
              :v2_question_page_step,
              id: 100,
              answer_type: "file",
              question_text: "Upload your evidence",
              position: "1",
              is_optional: true,
            ),
          ],
        )
      end

      context "and the question has been skipped" do
        let(:answers) do
          {
            "100" => {
              "file" => nil,
              "original_filename" => "",
              "uploaded_file_key" => nil,
              "filename_suffix" => "",
              "email_filename" => "",
            },
          }
        end

        it "does not set the email filename" do
          task.invoke(submission.reference)
          submission.reload
          expect(submission.answers["100"]).to include(
            "original_filename" => "",
            "email_filename" => "",
          )
        end
      end
    end

    context "when there is more than one file upload question" do
      let(:form_document) do
        build(
          :v2_form_document,
          steps: [
            build(
              :v2_question_page_step,
              id: 500,
              answer_type: "file",
              question_text: "Upload your evidence 1",
              position: "1",
            ),
            build(
              :v2_question_page_step,
              id: 501,
              answer_type: "file",
              question_text: "Upload your evidence 2",
              position: "2",
            ),
            build(
              :v2_question_page_step,
              id: 502,
              answer_type: "file",
              question_text: "Upload your evidence 2",
              position: "3",
            ),
            build(
              :v2_question_page_step,
              id: 503,
              answer_type: "file",
              question_text: "Upload your evidence 4",
              position: "4",
              is_optional: true,
            ),
          ],
        )
      end

      let(:answers) do
        {
          "500" => {
            "file" => nil,
            "original_filename" => "",
            "uploaded_file_key" => "#{Faker::Internet.uuid}.jpg",
            "filename_suffix" => "",
            "email_filename" => "",
          },
          "501" => {
            "file" => nil,
            "original_filename" => "",
            "uploaded_file_key" => "#{Faker::Internet.uuid}.jpg",
            "filename_suffix" => "",
            "email_filename" => "",
          },
          "502" => {
            "file" => nil,
            "original_filename" => "my-test-picture.jpg",
            "uploaded_file_key" => "#{Faker::Internet.uuid}.jpg",
            "filename_suffix" => "",
            "email_filename" => "",
          },
          "503" => {
            "file" => nil,
            "original_filename" => "",
            "uploaded_file_key" => nil,
            "filename_suffix" => "",
            "email_filename" => "",
          },
        }
      end

      it "fixes all answers missing original filename" do
        task.invoke(submission.reference)
        submission.reload
        expect(submission.answers).to match({
          "500" => a_hash_including("original_filename" => "", "email_filename" => "1-upload-your-evidence-1_F008AR.jpg"),
          "501" => a_hash_including("original_filename" => "", "email_filename" => "2-upload-your-evidence-2_F008AR.jpg"),
          "502" => a_hash_including("original_filename" => "my-test-picture.jpg", "email_filename" => ""),
          "503" => a_hash_including("original_filename" => "", "email_filename" => ""),
        })
      end
    end
  end
end
