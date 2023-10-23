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
end
