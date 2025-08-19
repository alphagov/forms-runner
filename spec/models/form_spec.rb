require "rails_helper"

RSpec.describe Form, type: :model do
  subject(:form) { described_class.new(attributes) }

  let(:attributes) { { id: 1, name: "form name", submission_email: "user@example.com", start_page: 1, pages: } }

  let(:pages) do
    [
      { id: 9, next_page: 10, answer_type: "date", question_text: "Question one" },
      { id: 10, answer_type: "address", question_text: "Question two" },
    ]
  end

  describe "#pages" do
    it "returns the pages for the form" do
      pages = form.pages
      expect(pages.length).to eq(2)
      expect(pages[0]).to have_attributes(id: 9, next_page: 10, answer_type: "date", question_text: "Question one")
      expect(pages[1]).to have_attributes(id: 10, answer_type: "address", question_text: "Question two")
    end
  end

  describe "#payment_url_with_reference" do
    let(:attributes) { { id: 1, name: "form name", payment_url:, start_page: 1 } }
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

  describe "#support_details" do
    let(:attributes) do
      {
        id: 1,
        name: "form name",
        support_email: "help@example.gov.uk",
        support_phone: "0203 222 2222",
        support_url: "https://example.gov.uk/help",
        support_url_text: "Get help with this form",
        start_page: 1,
      }
    end

    it "returns an OpenStruct with support details" do
      support_details = form.support_details

      expect(support_details.email).to eq("help@example.gov.uk")
      expect(support_details.phone).to eq("0203 222 2222")
      expect(support_details.url).to eq("https://example.gov.uk/help")
      expect(support_details.url_text).to eq("Get help with this form")
      expect(support_details.call_charges_url).to eq("https://www.gov.uk/call-charges")
    end
  end
end
