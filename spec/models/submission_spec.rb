require "rails_helper"

RSpec.describe Submission do
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
end
