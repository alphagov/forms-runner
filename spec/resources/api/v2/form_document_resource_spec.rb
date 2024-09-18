require "rails_helper"

RSpec.describe Api::V2::FormDocumentResource do
  let(:response_data) do
    { "form_id" => "1",
      "name" => "All question types form",
      "submission_email" => "",
      "privacy_policy_url" => "https://www.gov.uk/help/privacy-notice",
      "form_slug" => "all-question-types-form",
      "support_email" => "your.email+fakedata84701@gmail.com.gov.uk",
      "support_phone" => "08000800",
      "support_url" => nil,
      "support_url_text" => nil,
      "declaration_text" => "",
      "question_section_completed" => true,
      "declaration_section_completed" => true,
      "created_at" => "2024-09-05T06:25:25.558Z",
      "updated_at" => "2024-09-05T06:25:25.637Z",
      "creator_id" => nil,
      "organisation_id" => 1,
      "what_happens_next_markdown" => "Test",
      "payment_url" => nil,
      "start_page" => 1,
      "live_at" => "2024-09-05T06:25:25.637Z",
      "steps" =>
      [{ "id" => 1,
         "position" => 1,
         "next_step_id" => 2,
         "type" => "question_page",
         "data" =>
         { "question_text" => "Single line of text",
           "hint_text" => nil,
           "answer_type" => "text",
           "is_optional" => false,
           "answer_settings" => { "input_type" => "single_line" },
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] },
       { "id" => 2,
         "position" => 2,
         "next_step_id" => 3,
         "type" => "question_page",
         "data" =>
         { "question_text" => "Number",
           "hint_text" => nil,
           "answer_type" => "number",
           "is_optional" => false,
           "answer_settings" => nil,
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] },
       { "id" => 3,
         "position" => 3,
         "next_step_id" => 4,
         "type" => "question_page",
         "data" =>
         { "question_text" => "Address",
           "hint_text" => nil,
           "answer_type" => "address",
           "is_optional" => false,
           "answer_settings" =>
           { "input_type" => { "international_address" => false, "uk_address" => true } },
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] },
       { "id" => 4,
         "position" => 4,
         "next_step_id" => 5,
         "type" => "question_page",
         "data" =>
         { "question_text" => "Email address",
           "hint_text" => nil,
           "answer_type" => "email",
           "is_optional" => false,
           "answer_settings" => nil,
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] },
       { "id" => 5,
         "position" => 5,
         "next_step_id" => 6,
         "type" => "question_page",
         "data" =>
         { "question_text" => "Todays Date",
           "hint_text" => nil,
           "answer_type" => "date",
           "is_optional" => false,
           "answer_settings" => { "input_type" => "other_date" },
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] },
       { "id" => 6,
         "position" => 6,
         "next_step_id" => 7,
         "type" => "question_page",
         "data" =>
         { "question_text" => "National Insurance number",
           "hint_text" => nil,
           "answer_type" => "national_insurance_number",
           "is_optional" => false,
           "answer_settings" => nil,
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] },
       { "id" => 7,
         "position" => 7,
         "next_step_id" => 8,
         "type" => "question_page",
         "data" =>
         { "question_text" => "Phone number",
           "hint_text" => nil,
           "answer_type" => "phone_number",
           "is_optional" => false,
           "answer_settings" => nil,
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] },
       { "id" => 8,
         "position" => 8,
         "next_step_id" => 9,
         "type" => "question_page",
         "data" =>
         { "question_text" => "Selection from a list of options",
           "hint_text" => nil,
           "answer_type" => "selection",
           "is_optional" => true,
           "answer_settings" =>
           { "only_one_option" => "0",
             "selection_options" =>
             [{ "name" => "Option 1" }, { "name" => "Option 2" }, { "name" => "Option 3" }] },
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] },
       { "id" => 9,
         "position" => 9,
         "next_step_id" => nil,
         "type" => "question_page",
         "data" =>
         { "question_text" => "Multiple lines of text",
           "hint_text" => nil,
           "answer_type" => "text",
           "is_optional" => true,
           "answer_settings" => { "input_type" => "long_text" },
           "page_heading" => nil,
           "guidance_markdown" => nil,
           "is_repeatable" => false },
         "routing_conditions" => [] }] }
  end

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/1/live", req_headers, response_data.to_json, 200
    end
  end

  describe ".find" do
    it "finds a form document given a form id and document tag" do
      expect(described_class.find(1, :live)).to be_truthy
    end

    it "returns a v2 API form document" do
      form_document = described_class.find(1, :live)
      expect(form_document).to be_a described_class
      expect(form_document.steps).to all be_a described_class.const_get(:Step)
    end

    it "raises an exception if the form does not exist" do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v2/forms/99/draft", req_headers, nil, 404
      end

      expect {
        described_class.find("99", :draft)
      }.to raise_error(ActiveResource::ResourceNotFound)
    end

    context "when tag is live" do
      let(:response_data) { { id: 1, name: "form name", steps: [], live_at: "2022-08-18 09:16:50Z" } }

      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.get "/api/v2/forms/1/live", req_headers, response_data.to_json, 200
        end
      end

      it "returns a live form" do
        form = described_class.find(1, :live)

        expect(form).to have_attributes(id: 1, name: "form name")

        expect(ActiveResource::HttpMock.requests)
          .to include ActiveResource::Request.new(:get, "/api/v2/forms/1/live", nil, req_headers)
      end
    end

    context "when tag is draft" do
      let(:response_data) { { id: 1, name: "form name", steps: [], live_at: nil } }

      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.get "/api/v2/forms/1/draft", req_headers, response_data.to_json, 200
        end
      end

      it "returns a draft form" do
        form = described_class.find(1, :draft)

        expect(form).to have_attributes(id: 1, name: "form name")

        expect(ActiveResource::HttpMock.requests)
          .to include ActiveResource::Request.new(:get, "/api/v2/forms/1/draft", nil, req_headers)
      end
    end

    context "when mode is archived" do
      let(:response_data) { { id: 1, name: "form name", steps: [], live_at: "2022-08-18 09:16:50Z" } }

      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.get "/api/v2/forms/1/archived", req_headers, response_data.to_json, 200
        end
      end

      it "returns an archived form" do
        form = described_class.find(1, :archived)

        expect(form).to have_attributes(id: 1, name: "form name")

        expect(ActiveResource::HttpMock.requests)
          .to include ActiveResource::Request.new(:get, "/api/v2/forms/1/archived", nil, req_headers)
      end
    end
  end
end
