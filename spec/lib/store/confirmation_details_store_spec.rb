require "rails_helper"

RSpec.describe Store::ConfirmationDetailsStore do
  subject(:confirmation_details_store) { described_class.new(store) }

  let(:store) { {} }
  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:requested_email_confirmation) { true }

  it "stores and retrieves submission details" do
    confirmation_details_store.save_submission_details(1, reference, requested_email_confirmation)
    expect(confirmation_details_store.get_submission_reference(1)).to eq(reference)
    expect(confirmation_details_store.requested_email_confirmation?(1)).to eq(requested_email_confirmation)
  end

  it "stores the submission details for multiple forms without overwriting them" do
    confirmation_details_store.save_submission_details(1, reference, requested_email_confirmation)

    reference2 = Faker::Alphanumeric.alphanumeric(number: 8).upcase
    requested_email_confirmation2 = false
    confirmation_details_store.save_submission_details(2, reference2, requested_email_confirmation2)

    expect(confirmation_details_store.get_submission_reference(1)).to eq(reference)
    expect(confirmation_details_store.requested_email_confirmation?(1)).to eq(requested_email_confirmation)
    expect(confirmation_details_store.get_submission_reference(2)).to eq(reference2)
    expect(confirmation_details_store.requested_email_confirmation?(2)).to eq(requested_email_confirmation2)
  end

  describe "#clear_submission_details" do
    it "clears the submission details" do
      confirmation_details_store.save_submission_details(1, reference, requested_email_confirmation)

      confirmation_details_store.clear_submission_details(1)

      expect(confirmation_details_store.get_submission_reference(1)).to be_nil
      expect(confirmation_details_store.requested_email_confirmation?(1)).to be_nil
    end
  end
end
