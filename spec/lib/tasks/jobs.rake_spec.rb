require "rake"
require "rails_helper"

RSpec.describe "jobs.rake" do
  include ActiveJob::TestHelper

  before do
    Rake.application.rake_require "tasks/jobs"
    Rake::Task.define_task(:environment)
  end

  describe "jobs:retry_failed_send_job" do
    subject(:task) do
      Rake::Task["jobs:retry_failed_send_job"]
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
               .and output("usage: rake jobs:retry_failed_send_job[<job_id>]\n").to_stderr
      end
    end
  end

  describe "jobs:retry_all_failed_send_jobs" do
    subject(:task) do
      Rake::Task["jobs:retry_all_failed_send_jobs"]
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
end
