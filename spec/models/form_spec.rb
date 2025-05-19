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

  shared_examples "form snapshot" do
    it "returns a simple form" do
      expect(form).to have_attributes(id: 1, name: "form name", submission_email: "user@example.com")
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
  end

  context "when mode is live" do
    let(:attributes) { { id: 1, name: "form name", submission_email: "user@example.com", live_at: "2022-08-18 09:16:50Z", pages: } }

    it_behaves_like "form snapshot"

    it "returns a live form" do
      expect(form).to have_attributes(id: 1, name: "form name")
      expect(form.live?).to be(true)
    end

    describe "#live?" do
      let(:attributes) { { id: 1, name: "form name", live_at: }.compact }
      let(:live_at) { "2022-08-18 09:16:50Z" }

      context "when live_at is not set" do
        let(:live_at) { nil }

        it "raises an error" do
          expect { form.live? }.to raise_error(Date::Error)
        end
      end

      context "when live_at is set to empty string" do
        let(:live_at) { "" }

        it "returns false" do
          expect(form.live?).to be false
        end
      end

      context "when live_at is a string which isn't a valid date" do
        let(:live_at) { "not a date!" }

        it "raises an error" do
          expect { form.live? }.to raise_error(Date::Error)
        end
      end

      context "when live_at is not a string" do
        let(:live_at) { 1 }

        it "raises an error" do
          expect { form.live? }.to raise_error(Date::Error)
        end
      end

      context "when live_at is a date in the future" do
        let(:live_at) { "2022-08-18 09:16:50Z" }

        it "returns false" do
          expect(form.live?("2022-01-01 10:00:00Z")).to be false
        end
      end

      context "when live_at is a date in the past" do
        let(:live_at) { "2022-08-18 09:16:50Z" }

        it "returns true" do
          expect(form.live?("2023-01-01 10:00:00Z")).to be true
        end
      end

      context "when dates are the same" do
        let(:live_at) { "2022-08-18 09:16:50Z" }

        it "returns false" do
          expect(form.live?("2022-08-18 09:16:50Z")).to be false
        end
      end
    end

    context "when mode is draft" do
      let(:attributes) { { id: 1, name: "form name", submission_email: "user@example.com", live_at: nil, pages: } }

      it_behaves_like "form snapshot"

      it "returns a draft form" do
        expect(form).to have_attributes(id: 1, name: "form name")
        expect(form.live?).to be(false)
      end
    end
  end
end
