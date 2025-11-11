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

  describe "#form_id" do
    context "when the form is initialised with attribute form_id" do
      let(:attributes) { { form_id: "1" } }

      it "returns the form ID" do
        expect(form).to have_attributes form_id: "1"
      end

      it "equals #id" do
        expect(form.form_id).to eq form.id
      end
    end

    context "when the form is initialised with attribute id" do
      let(:attributes) { { id: 1 } }

      it "returns the form ID" do
        expect(form).to have_attributes form_id: 1
      end

      it "equals #id" do
        expect(form.form_id).to eq form.id
      end
    end
  end

  describe "#pages" do
    it "returns the pages for the form" do
      pages = form.pages
      expect(pages.length).to eq(2)
      expect(pages[0]).to have_attributes(id: 9, next_page: 10, answer_type: "date", question_text: "Question one")
      expect(pages[1]).to have_attributes(id: 10, answer_type: "address", question_text: "Question two")
    end

    context "when the form is initialised with steps" do
      let(:attributes) { { steps: } }

      let(:steps) do
        [
          { id: 9, next_step_id: 10, type: "question_page", data: { answer_type: "date", question_text: "Question one" } },
          { id: 10, type: "question_page", data: { answer_type: "address", question_text: "Question two" } },
        ]
      end

      it "returns the pages for the form" do
        pages = form.pages
        expect(pages.length).to eq(2)
        expect(pages[0]).to have_attributes(id: 9, next_page: 10, answer_type: "date", question_text: "Question one")
        expect(pages[1]).to have_attributes(id: 10, answer_type: "address", question_text: "Question two")
      end
    end

    context "when the form document in the API has steps" do
      subject(:form) { described_class.find(:one, from: "/api/v2/forms/1/live") }

      let(:attributes) { { id: 1, name: "form name", submission_email: "user@example.com", start_page: 1, steps: } }

      let(:steps) do
        [
          { id: 9, next_step_id: 10, type: "question_page", data: { answer_type: "date", question_text: "Question one" } },
          { id: 10, type: "question_page", data: { answer_type: "address", question_text: "Question two" } },
        ]
      end

      let(:req_headers) { { "Accept" => "application/json" } }

      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.get "/api/v2/forms/1/live", req_headers, attributes.to_json, 200
        end
      end

      it "returns the pages for the form" do
        pages = form.pages
        expect(pages.length).to eq(2)
        expect(pages[0]).to have_attributes(id: 9, next_page: 10, answer_type: "date", question_text: "Question one")
        expect(pages[1]).to have_attributes(id: 10, answer_type: "address", question_text: "Question two")
      end
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

  describe "#submission_method" do
    context "when the submission type is blank" do
      let(:attributes) { { submission_type: nil } }

      it "returns the submission delivery method :email" do
        expect(form.submission_method).to eq :email
      end
    end

    [
      ["email", :email],
      ["email_with_csv", :email],
      ["email_with_json", :email],
      ["email_with_csv_and_json", :email],
      ["s3", :s3],
      ["s3_with_json", :s3],
    ].each do |submission_type, expected_submission_method|
      context "when the submission type is #{submission_type}" do
        let(:attributes) { { submission_type: } }

        it "returns the submission delivery method :#{expected_submission_method}" do
          expect(form.submission_method).to eq expected_submission_method
        end
      end
    end

    context "when the submission type is unrecognized" do
      let(:attributes) { { submission_type: "something_else_with_csv" } }

      it "raises an error" do
        expect { form.submission_method }.to raise_error(/something_else_with_csv/)
      end
    end
  end

  describe "#submission_format" do
    context "when the submission format attribute is nil" do
      let(:attributes) { { submission_format: nil } }

      it "returns no submission delivery formats" do
        expect(form.submission_format).to eq []
      end
    end

    [
      [[], []],
      [%w[csv], %i[csv]],
      [%w[json], %i[json]],
      [%w[csv json], %i[csv json]],
    ].each do |submission_format, expected_submission_format|
      context "when the submission format attribute is #{submission_format}" do
        let(:attributes) { { submission_format: } }

        it "returns the submission delivery formats #{expected_submission_format}" do
          expect(form.submission_format).to eq expected_submission_format
        end
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
