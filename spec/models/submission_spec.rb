require "rails_helper"

RSpec.describe Submission, type: :model do
  describe "#sent?" do
    context "when the submission is sent?" do
      let(:submission) { create :submission, :sent }

      it "returns true" do
        expect(described_class).to be_sent(submission.reference)
      end
    end

    context "when there is a submission is unsent" do
      let(:submission) { create :submission }

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
end
