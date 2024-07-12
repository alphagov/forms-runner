require "rails_helper"

RSpec.describe Form, type: :model, feature_direct_api_enabled: false do
  describe "#live?" do
    let(:form) { build :form }

    it "when no live_at is set to empty string returns false" do
      form.live_at = ''
      expect(form.live?).to be false
    end

    it "when live_at is a string which isn't a valid date raises an error" do
      form.live_at = 'invalid date'
      expect { form.live? }.to raise_error(Date::Error)
    end

    it "when live_at is not a string raises an error" do
      form.live_at = 1
      expect { form.live? }.to raise_error(Date::Error)
    end

    it "when live_at is a date in the future returns false" do
      form.live_at = "2022-08-18 09:16:50Z"
      expect(form.live?("2022-01-01 10:00:00Z")).to be false
    end

    it "when live_at is a date in the past returns true" do
      form.live_at = "2022-08-18 09:16:50Z"
      expect(form.live?("2023-01-01 10:00:00Z")).to be true
    end

    it "when dates are the same returns false" do
      form.live_at = "2022-08-18 09:16:50Z"
      expect(form.live?("2022-08-18 09:16:50Z")).to be false
    end
  end

  describe "#payment_url_with_reference" do
    let(:form) { build :form, payment_url: }
    let(:reference) { SecureRandom.base58(8).upcase }

    context "when there is a payment_url" do
      let(:payment_url) { "https://www.gov.uk/payments/test-service/pay-for-licence" }

      it "returns a full payment link" do
        expect(form.payment_url_with_reference(reference)).to eq("#{payment_url}?reference=#{reference}")
      end
    end

    context "when there is no payment_url" do
      let(:payment_url) { nil }

      it "returns nil" do
        expect(form.payment_url_with_reference(reference)).to be_nil
      end
    end
  end
end
