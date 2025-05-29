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

  describe "mail_status" do
    let(:submission) { create :submission }

    describe "validations" do
      it "is valid for a submission's mail_status to be pending" do
        submission.pending!
        expect(submission).to be_valid
      end

      it "is valid for a submission's mail_status to be bounced" do
        submission.bounced!
        expect(submission).to be_valid
      end

      it "is not valid for a submission's mail_status to be something else" do
        expect { submission.mail_status = "some other string" }.to raise_error(ArgumentError).with_message(/is not a valid mail_status/)
      end
    end

    describe "mail_status enum" do
      it "returns a list of mail statuses" do
        expect(described_class.mail_statuses.keys).to eq(%w[pending bounced])
        expect(described_class.mail_statuses.values).to eq(%w[pending bounced])
      end
    end
  end
end
