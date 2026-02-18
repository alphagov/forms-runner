require "rails_helper"

RSpec.describe Submission, type: :model do
  describe "scopes" do
    describe ".for_daily_batch" do
      context "when the date is during BST" do
        let(:form_id) { 101 }
        let!(:start_of_day_submission) { create(:submission, form_id:, created_at: Time.utc(2022, 5, 31, 23, 0, 0), mode:) }
        let!(:end_of_day_submission) { create(:submission, form_id:, created_at: Time.utc(2022, 6, 1, 22, 59, 59), mode:) }
        let(:mode) { "form" }
        let(:date) { Date.new(2022, 6, 1) }

        before do
          create(:submission, form_id: 5, created_at: Time.utc(2022, 6, 1, 12, 0, 0), mode:)
          create(:submission, form_id:, created_at: Time.utc(2022, 5, 31, 22, 59, 59), mode:)
          create(:submission, form_id:, created_at: Time.utc(2022, 6, 1, 23, 0, 0), mode:)
          create(:submission, form_id:, created_at: Time.utc(2022, 6, 2, 12, 0, 0), mode: "preview-live")
        end

        it "returns only submissions for the given form, date and mode" do
          submissions = described_class.for_daily_batch(form_id, date, mode)
          expect(submissions.size).to eq(2)
          expect(submissions).to contain_exactly(start_of_day_submission, end_of_day_submission)
        end
      end

      context "when the date is not during BST" do
        let(:form_id) { 101 }
        let!(:start_of_day_submission) { create(:submission, form_id:, created_at: Time.utc(2022, 12, 1, 0, 0, 0), mode:) }
        let!(:end_of_day_submission) { create(:submission, form_id:, created_at: Time.utc(2022, 12, 1, 23, 59, 59), mode:) }
        let(:mode) { "form" }
        let(:date) { Date.new(2022, 12, 1) }

        before do
          create(:submission, form_id: 5, created_at: Time.utc(2022, 12, 1, 12, 0, 0), mode:)
          create(:submission, form_id:, created_at: Time.utc(2022, 11, 30, 23, 59, 59), mode:)
          create(:submission, form_id:, created_at: Time.utc(2022, 12, 2, 0, 0, 0), mode:)
          create(:submission, form_id:, created_at: Time.utc(2022, 12, 1, 12, 0, 0), mode: "preview-live")
        end

        it "returns only submissions for the given form, date and mode" do
          submissions = described_class.for_daily_batch(form_id, date, mode)
          expect(submissions.size).to eq(2)
          expect(submissions).to contain_exactly(start_of_day_submission, end_of_day_submission)
        end
      end
    end

    describe ".ordered_by_form_version_and_date" do
      let(:first_form_version) { create :v2_form_document, updated_at: Time.utc(2022, 6, 1, 12, 0, 0) }
      let(:second_form_version) { create :v2_form_document, updated_at: Time.utc(2022, 12, 1, 12, 0, 0) }

      before do
        create :submission, form_document: second_form_version, created_at: Time.utc(2022, 12, 1, 21, 0, 0), reference: "fourth_submission"
        create :submission, form_document: first_form_version, created_at: Time.utc(2022, 12, 1, 15, 0, 0), reference: "third_submission"
        create :submission, form_document: second_form_version, created_at: Time.utc(2022, 12, 1, 13, 0, 0), reference: "second_submission"
        create :submission, form_document: first_form_version, created_at: Time.utc(2022, 12, 1, 9, 0, 0), reference: "first_submission"
      end

      it "returns the submissions in order" do
        expect(described_class.all.ordered_by_form_version_and_date.pluck(:reference)).to eq(%w[first_submission third_submission second_submission fourth_submission])
      end
    end
  end

  describe "#sent?" do
    context "when the submission is sent" do
      let(:submission) { create :submission, :sent }

      it "returns true" do
        expect(described_class).to be_sent(submission.reference)
      end
    end

    context "when the submission is not sent" do
      let(:submission) { create :submission, deliveries: [create(:delivery, :not_sent)] }

      it "returns false" do
        expect(described_class).not_to be_sent(submission.reference)
      end
    end

    context "when there is no submission" do
      it "returns false" do
        expect(described_class).not_to be_sent("999")
      end
    end
  end

  describe "#submission_time" do
    subject(:submission) { described_class.create!(created_at: created_at) }

    context "with a time in BST" do
      let(:created_at) { Time.utc(2022, 9, 14, 7, 0, 0) }

      it "has BST timezone" do
        expect(submission.submission_time.zone).to eq("BST")
      end

      it "returns the local time when stringified" do
        expect(submission.submission_time.strftime("%-d %B %Y - %l:%M%P")).to eq("14 September 2022 -  8:00am")
      end
    end

    context "with a time in GMT" do
      let(:created_at) { Time.utc(2022, 12, 14, 13, 0, 0) }

      it "has GMT timezone" do
        expect(submission.submission_time.zone).to eq("GMT")
      end

      it "returns the local time when stringified" do
        expect(submission.submission_time.strftime("%-d %B %Y - %l:%M%P")).to eq("14 December 2022 -  1:00pm")
      end
    end
  end

  describe "#single_submission_delivery" do
    context "when there is a single delivery with 'immediate' delivery_schedule" do
      let(:submission) { create :submission }
      let!(:delivery) { submission.deliveries.create!(delivery_schedule: :immediate) }

      before do
        submission.deliveries.create!(delivery_schedule: :daily)
      end

      it "returns the delivery without a batch frequency" do
        expect(submission.single_submission_delivery).to eq(delivery)
      end
    end

    context "when there are multiple deliveries with 'immediate' delivery_schedule" do
      let(:submission) { create :submission }

      before do
        submission.deliveries.create!(delivery_schedule: :immediate)
        submission.deliveries.create!(delivery_schedule: :immediate)
      end

      it "raises an error" do
        expect {
          submission.single_submission_delivery
        }.to raise_error(ActiveRecord::SoleRecordExceeded)
      end
    end

    context "when there is a single delivery with 'daily' delivery_schedule" do
      let(:submission) { create :submission }

      before do
        submission.deliveries.create!(delivery_schedule: :daily)
      end

      it "raises an error" do
        expect {
          submission.single_submission_delivery
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "submission_locale" do
    subject(:submission) { create :submission }

    it "returns the submission locale" do
      expect(submission.submission_locale).to eq("en")
    end
  end

  describe "destroy" do
    subject(:submission) { create :submission }

    context "when there is a delivery only associated to this submission" do
      let!(:delivery) { submission.deliveries.create!(delivery_reference: "message-id") }

      it "destroys the SubmissionDelivery join record" do
        expect {
          submission.destroy
        }.to change(SubmissionDelivery, :count).by(-1)
      end

      it "destroys associated delivery record" do
        submission.destroy!
        expect(Delivery.exists?(delivery.id)).to be false
      end
    end

    context "when there is a delivery associated to multiple submissions" do
      let(:delivery) { create :delivery, delivery_reference: "message-id" }

      before do
        other_submission = create :submission
        SubmissionDelivery.create!(submission: submission, delivery: delivery)
        SubmissionDelivery.create!(submission: other_submission, delivery: delivery)
      end

      it "destroys the SubmissionDelivery join record" do
        expect {
          submission.destroy
        }.to change(SubmissionDelivery, :count).by(-1)
      end

      it "does not destroy associated delivery record" do
        submission.destroy!
        expect(Delivery.exists?(delivery.id)).to be true
      end
    end
  end

  describe ".group_by_form_version" do
    subject(:grouped_submissions) { described_class.group_by_form_version(submissions) }

    let(:first_version_updated_at) { Time.utc(2022, 9, 14, 7, 0, 0).iso8601(3) }
    let(:second_version_updated_at) { Time.utc(2022, 9, 15, 7, 0, 0).iso8601(3) }
    let(:third_version_updated_at) { Time.utc(2022, 9, 16, 7, 0, 0).iso8601(3) }

    let(:form_document) { create :v2_form_document, :with_steps, updated_at: first_version_updated_at }
    let(:form_document_same_steps) { create :v2_form_document, updated_at: second_version_updated_at, steps: form_document.steps }
    let(:form_document_different_steps) { create :v2_form_document, :with_steps, updated_at: third_version_updated_at }

    let(:first_version_submissions) { create_list :submission, 2, form_document: }
    let(:second_version_submissions) { create_list :submission, 3, form_document: form_document_same_steps }
    let(:third_version_submissions) { create_list :submission, 4, form_document: form_document_different_steps }

    # the submissions are ordered non-sequentially to check the method sorts the resulting versions
    let(:submissions) { third_version_submissions + first_version_submissions + second_version_submissions }

    it "has the expected keys in date order" do
      expect(grouped_submissions.keys).to eq([first_version_updated_at, third_version_updated_at])
    end

    it "groups all submission with the same updated_at together" do
      expect(grouped_submissions).to have_key(first_version_updated_at)
      expect(grouped_submissions[first_version_updated_at].pluck(:id)).to include(*first_version_submissions.pluck(:id))
    end

    it "groups submission with different updated_at but same steps together" do
      expect(grouped_submissions[first_version_updated_at]).to match_array(first_version_submissions + second_version_submissions)
      expect(grouped_submissions).not_to have_key(second_version_updated_at)
    end

    it "groups submissions with different updated_at and different steps separately" do
      expect(grouped_submissions[third_version_updated_at]).to match_array(third_version_submissions)
    end
  end
end
