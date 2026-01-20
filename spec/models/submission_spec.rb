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

  describe "delivery_status" do
    let(:submission) { create :submission }

    describe "validations" do
      it "is valid for a submission's delivery_status to be pending" do
        submission.pending!
        expect(submission).to be_valid
      end

      it "is valid for a submission's delivery_status to be bounced" do
        submission.bounced!
        expect(submission).to be_valid
      end

      it "is not valid for a submission's delivery_status to be something else" do
        expect { submission.delivery_status = "some other string" }.to raise_error(ArgumentError).with_message(/is not a valid delivery_status/)
      end
    end

    describe "delivery_status enum" do
      it "returns a list of delivery statuses" do
        expect(described_class.delivery_statuses.keys).to eq(%w[pending bounced])
        expect(described_class.delivery_statuses.values).to eq(%w[pending bounced])
      end
    end
  end

  describe "submission_locale" do
    subject(:submission) { create :submission }

    it "returns the submission locale" do
      expect(submission.submission_locale).to eq("en")
    end
  end
end
