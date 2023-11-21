require "rails_helper"

RSpec.describe EmailConfirmationForm, type: :model do
  let(:email_confirmation_form) { build :email_confirmation_form }

  context "when the email confirmations flag is enabled", feature_email_confirmations_enabled: true do
    context "when given an empty string or nil" do
      it "returns invalid with blank email" do
        expect(email_confirmation_form).not_to be_valid
        expect(email_confirmation_form.errors[:send_confirmation]).to include(I18n.t("activemodel.errors.models.email_confirmation_form.attributes.send_confirmation.blank"))
      end
    end

    context "when user opts in and provides a valid email address" do
      let(:email_confirmation_form) { build :email_confirmation_form_opted_in }

      it "validates" do
        expect(email_confirmation_form).to be_valid
        expect(email_confirmation_form.errors[:confirmation_email_address]).to be_empty
      end
    end

    context "when user opts in and provides an invalid email address" do
      let(:email_confirmation_form) { build :email_confirmation_form_opted_in, confirmation_email_address: "not an email address" }

      it "does not validate an address without an @" do
        expect(email_confirmation_form).not_to be_valid
        expect(email_confirmation_form.errors[:confirmation_email_address]).to include(I18n.t("activemodel.errors.models.email_confirmation_form.attributes.confirmation_email_address.invalid_email"))
      end
    end

    context "when send_confirmation is false" do
      let(:email_confirmation_form) { build :email_confirmation_form, send_confirmation: "skip_confirmation" }

      it "returns valid with blank email" do
        expect(email_confirmation_form).to be_valid
        expect(email_confirmation_form.errors[:confirmation_email_address]).to be_empty
      end

      it "returns valid with empty string" do
        email_confirmation_form.confirmation_email_address = ""
        expect(email_confirmation_form).to be_valid
      end
    end
  end

  context "when the email confirmations flag is not enabled", feature_email_confirmations_enabled: false do
    context "when send_confirmation is null" do
      it "returns valid" do
        expect(email_confirmation_form).to be_valid
        expect(email_confirmation_form.errors[:send_confirmation]).to be_empty
      end
    end
  end

  describe "#generate_submission_references!" do
    uuid = /[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/

    before do
      email_confirmation_form.generate_submission_references!
    end

    let(:notify_reference) { email_confirmation_form.notify_reference }
    let(:confirmation_email_reference) { email_confirmation_form.confirmation_email_reference }

    it "generates a random submission notification reference" do
      expect(notify_reference)
        .to match(uuid).and end_with("-submission-email")
    end

    it "generates a random email confirmation notification reference" do
      expect(confirmation_email_reference)
        .to match(uuid).and end_with("-confirmation-email")
    end

    it "generates a different string for all notification references" do
      expect(notify_reference).not_to eq confirmation_email_reference
    end

    it "includes a common identifier in all notification references" do
      uuid_in = ->(str) { uuid.match(str).to_s }

      expect(uuid_in[notify_reference]).to eq uuid_in[confirmation_email_reference]
    end
  end
end
