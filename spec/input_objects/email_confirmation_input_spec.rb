require "rails_helper"

RSpec.describe EmailConfirmationInput, type: :model do
  let(:email_confirmation_input) { build :email_confirmation_input }
  let(:invalid_emails) do
    ["email@123.123.123.123",
     "email@[123.123.123.123]",
     "plainaddress",
     "@no-local-part.com",
     "Outlook Contact <outlook-contact@domain.com>",
     "no-at.domain.com",
     "no-tld@domain",
     ";beginning-semicolon@domain.co.uk",
     "middle-semicolon@domain.co;uk",
     "trailing-semicolon@domain.com;",
     '"email+leading-quotes@domain.com',
     'email+middle"-quotes@domain.com',
     '"quoted-local-part"@domain.com',
     '"quoted@domain.com"',
     "lots-of-dots@domain..gov..uk",
     "two-dots..in-local@domain.com",
     "multiple@domains@domain.com",
     "spaces in local@domain.com",
     "spaces-in-domain@dom ain.com",
     "underscores-in-domain@dom_ain.com",
     "pipe-in-domain@example.com|gov.uk",
     "comma,in-local@gov.uk",
     "comma-in-domain@domain,gov.uk",
     "pound-sign-in-local£@domain.com",
     "local-with-’-apostrophe@domain.com",
     "local-with-”-quotes@domain.com",
     "domain-starts-with-a-dot@.domain.com",
     "brackets(in)local@domain.com",
     "email-too-long-#{'a' * 320}@example.com",
     "incorrect-punycode@xn---something.com"]
  end

  context "when given an empty string or nil" do
    it "returns invalid with blank email" do
      expect(email_confirmation_input).not_to be_valid
      expect(email_confirmation_input.errors[:send_confirmation]).to include(I18n.t("activemodel.errors.models.email_confirmation_input.attributes.send_confirmation.blank"))
    end
  end

  context "when user opts in and provides a valid email address" do
    let(:email_confirmation_input) { build :email_confirmation_input_opted_in }

    it "validates" do
      expect(email_confirmation_input).to be_valid
      expect(email_confirmation_input.errors[:confirmation_email_address]).to be_empty
    end
  end

  context "when user opts in and provides an invalid email address" do
    it "does not allow invalid emails" do
      invalid_emails.each do |invalid_email|
        email_confirmation_input = build :email_confirmation_input_opted_in, confirmation_email_address: invalid_email

        expect(email_confirmation_input).not_to be_valid
        expect(email_confirmation_input.errors[:confirmation_email_address]).to include(I18n.t("activemodel.errors.models.email_confirmation_input.attributes.confirmation_email_address.invalid_email"))
      end
    end
  end

  context "when send_confirmation is false" do
    let(:email_confirmation_input) { build :email_confirmation_input, send_confirmation: "skip_confirmation" }

    it "returns valid with blank email" do
      expect(email_confirmation_input).to be_valid
      expect(email_confirmation_input.errors[:confirmation_email_address]).to be_empty
    end

    it "returns valid with empty string" do
      email_confirmation_input.confirmation_email_address = ""
      expect(email_confirmation_input).to be_valid
    end
  end

  describe "submission references" do
    uuid = /[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/

    let(:email_confirmation_input) do
      described_class.new
    end

    let(:confirmation_email_reference) { email_confirmation_input.confirmation_email_reference }

    it "generates a random email confirmation notification reference" do
      expect(confirmation_email_reference)
        .to match(uuid).and end_with("-confirmation-email")
    end

    context "when intialised with references" do
      let(:email_confirmation_input) do
        described_class.new(
          confirmation_email_reference: "foo",
        )
      end

      it "does not generate new references" do
        expect(confirmation_email_reference).to eq "foo"
      end
    end
  end
end
