require "rails_helper"

RSpec.describe Submission, type: :model do
  let(:submission) { create :submission }

  describe "mail_status" do
    describe "validations" do
      it "is valid for a submission's mail_status to be pending" do
        submission.mail_status = :pending
        expect(submission).to be_valid
      end

      it "is valid for a submission's mail_status to be delivered" do
        submission.mail_status = :delivered
        expect(submission).to be_valid
      end

      it "is valid for a submission's mail_status to be bounced" do
        submission.mail_status = :bounced
        expect(submission).to be_valid
      end

      it "is not valid for a submission's mail_status to be something else" do
        expect { submission.mail_status = "some other string" }.to raise_error(ArgumentError).with_message(/is not a valid mail_status/)
      end
    end

    describe "mail_status enum" do
      it "returns a list of mail statuses" do
        expect(described_class.mail_statuses.keys).to eq(%w[pending delivered bounced])
        expect(described_class.mail_statuses.values).to eq(%w[pending delivered bounced])
      end
    end
  end
end
