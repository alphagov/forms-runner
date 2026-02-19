require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
RSpec.describe SendSubmissionBatchJob, type: :job do
  include ActiveJob::TestHelper

  let(:mode_string) { "form" }
  let(:date) { Date.new(2022, 12, 14) }
  let(:delivery) { create(:delivery, delivery_schedule: "daily") }

  let(:form_document) { create(:v2_form_document, :with_steps, name: "My Form", submission_email:) }
  let(:submission_email) { "to@example.com" }
  let(:form_id) { form_document.form_id }
  let(:submissions) { [] }

  before do
    submissions
    ActionMailer::Base.deliveries.clear
    described_class.perform_later(form_id:, mode_string:, date:, delivery:)
  end

  context "when there are no submissions" do
    before do
      perform_enqueued_jobs
    end

    it "does not send an email" do
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "does not update the delivery" do
      expect(delivery.reload.last_attempt_at).to be_nil
    end
  end

  context "when there are submissions" do
    let(:submissions_to_include) do
      create_list(
        :submission,
        3,
        form_document:,
        form_id:,
        mode: mode_string,
        created_at: date.beginning_of_day + 1.hour,
      )
    end
    let(:submission_not_on_date) do
      create(:submission, form_document:, form_id:, mode: mode_string, created_at: date.beginning_of_day - 1.day)
    end
    let(:preview_submission) do
      create(:submission, :preview, form_document:, form_id:, created_at: date.beginning_of_day + 1.hour)
    end
    let(:submissions) { [submissions_to_include, submission_not_on_date, preview_submission] }

    context "when the form does not have a submission email address" do
      let(:submission_email) { nil }

      it "raises an error" do
        expect {
          perform_enqueued_jobs
        }.to raise_error(StandardError, "Form id: #{form_id} is missing a submission email address")
      end

      context "when the mode is preview" do
        let(:mode_string) { "preview-live" }

        it "does not call the submission batch service" do
          perform_enqueued_jobs
          expect(AwsSesSubmissionBatchService).not_to receive(:new)
        end
      end
    end

    context "when the form has a submission email address" do
      before do
        @job_ran_at = Time.zone.now
        perform_enqueued_jobs
      end

      it "sends an email" do
        expect(ActionMailer::Base.deliveries.count).to eq(1)

        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to include(form_document.submission_email)
      end

      it "updates the delivery" do
        mail = ActionMailer::Base.deliveries.last
        expect(delivery.reload.delivery_reference).to eq(mail.message_id)
        expect(delivery.reload.last_attempt_at).to be_within(1.second).of(@job_ran_at)
      end

      it "attaches a csv with the expected filename" do
        mail = ActionMailer::Base.deliveries.last
        expect(mail.attachments).not_to be_empty

        filenames = mail.attachments.map(&:filename)
        expect(filenames).to contain_exactly("govuk_forms_my_form_2022-12-14.csv")
      end

      it "attaches a csv containing header plus one line per submission" do
        mail = ActionMailer::Base.deliveries.last

        csv_content = mail.attachments.first.decoded
        expect(csv_content.lines.count).to eq(submissions_to_include.count + 1)
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
