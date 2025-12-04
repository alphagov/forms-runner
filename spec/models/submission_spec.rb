require "rails_helper"

RSpec.describe Submission, type: :model do
  describe "#emailed?" do
    context "when the submission has a mail_message_id" do
      it "returns true" do
        described_class.create!(reference: "123", mail_message_id: "456")

        expect(described_class).to be_emailed("123")
      end
    end

    context "when there is a submission but no mail_message_id" do
      it "returns false" do
        described_class.create!(reference: "789")

        expect(described_class).not_to be_emailed("789")
      end
    end

    context "when there is no submission" do
      it "returns false" do
        expect(described_class).not_to be_emailed("999")
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

  describe "#status" do
    subject(:status) { submission.status }

    let(:submission) { build :submission, delivered_at:, bounced_at: }
    let(:delivered_at) { nil }
    let(:bounced_at) { nil }

    context "when delivered_at and bounced_at are nil" do
      it { is_expected.to eq :pending }
    end

    context "when delivered_at is set" do
      let(:delivered_at) { Time.current }

      it { is_expected.to eq :delivered }

      context "when bounced_at is set later" do
        let(:bounced_at) { delivered_at + 1.hour }

        it { is_expected.to eq :delivered }
      end

      context "when bounced_at is set earlier" do
        let(:bounced_at) { delivered_at - 1.hour }

        it { is_expected.to eq :bounced }
      end
    end

    context "when bounced_at is set" do
      let(:bounced_at) { Time.current }

      it { is_expected.to eq :bounced }

      context "when delivered_at is set later" do
        let(:delivered_at) { bounced_at + 1.hour }

        it { is_expected.to eq :bounced }
      end
    end
  end

  describe "scopes" do
    let!(:pending_submission) { create :submission, delivered_at: nil, bounced_at: nil }
    let!(:delivered_submission) { create :submission, delivered_at: Time.current, bounced_at: nil }
    let!(:bounced_submission) { create :submission, delivered_at: nil, bounced_at: Time.current }
    let!(:delivered_then_bounced_submission) { create :submission, delivered_at: Time.current, bounced_at: Time.current + 1.hour }
    let!(:bounced_then_delivered_submission) { create :submission, delivered_at: Time.current + 1.hour, bounced_at: Time.current }

    describe ".pending" do
      it "returns pending submissions" do
        expect(described_class.pending).to contain_exactly(pending_submission)
      end
    end

    describe ".delivered" do
      it "returns delivered submissions" do
        expect(described_class.delivered).to contain_exactly(delivered_submission, delivered_then_bounced_submission)
      end
    end

    describe ".bounced" do
      it "returns bounced submissions" do
        expect(described_class.bounced).to contain_exactly(bounced_submission, bounced_then_delivered_submission)
      end
    end
  end
end
