require "rails_helper"

RSpec.describe Api::V1::FormSnapshotRepository do
  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:api_v1_response_data) do
    { "id" => 1,
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
      "pages" =>
      [{ "id" => 1,
         "question_text" => "Single line of text",
         "hint_text" => nil,
         "answer_type" => "text",
         "next_page" => 2,
         "is_optional" => false,
         "answer_settings" => { "input_type" => "single_line" },
         "created_at" => "2024-09-05T06:25:25.574Z",
         "updated_at" => "2024-09-05T06:25:25.574Z",
         "position" => 1,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] },
       { "id" => 2,
         "question_text" => "Number",
         "hint_text" => nil,
         "answer_type" => "number",
         "next_page" => 3,
         "is_optional" => false,
         "answer_settings" => {},
         "created_at" => "2024-09-05T06:25:25.578Z",
         "updated_at" => "2024-09-05T06:25:25.578Z",
         "position" => 2,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] },
       { "id" => 3,
         "question_text" => "Address",
         "hint_text" => nil,
         "answer_type" => "address",
         "next_page" => 4,
         "is_optional" => false,
         "answer_settings" =>
         { "input_type" => { "international_address" => false, "uk_address" => true } },
         "created_at" => "2024-09-05T06:25:25.582Z",
         "updated_at" => "2024-09-05T06:25:25.582Z",
         "position" => 3,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] },
       { "id" => 4,
         "question_text" => "Email address",
         "hint_text" => nil,
         "answer_type" => "email",
         "next_page" => 5,
         "is_optional" => false,
         "answer_settings" => {},
         "created_at" => "2024-09-05T06:25:25.584Z",
         "updated_at" => "2024-09-05T06:25:25.584Z",
         "position" => 4,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] },
       { "id" => 5,
         "question_text" => "Todays Date",
         "hint_text" => nil,
         "answer_type" => "date",
         "next_page" => 6,
         "is_optional" => false,
         "answer_settings" => { "input_type" => "other_date" },
         "created_at" => "2024-09-05T06:25:25.589Z",
         "updated_at" => "2024-09-05T06:25:25.589Z",
         "position" => 5,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] },
       { "id" => 6,
         "question_text" => "National Insurance number",
         "hint_text" => nil,
         "answer_type" => "national_insurance_number",
         "next_page" => 7,
         "is_optional" => false,
         "answer_settings" => {},
         "created_at" => "2024-09-05T06:25:25.591Z",
         "updated_at" => "2024-09-05T06:25:25.591Z",
         "position" => 6,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] },
       { "id" => 7,
         "question_text" => "Phone number",
         "hint_text" => nil,
         "answer_type" => "phone_number",
         "next_page" => 8,
         "is_optional" => false,
         "answer_settings" => {},
         "created_at" => "2024-09-05T06:25:25.592Z",
         "updated_at" => "2024-09-05T06:25:25.592Z",
         "position" => 7,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] },
       { "id" => 8,
         "question_text" => "Selection from a list of options",
         "hint_text" => nil,
         "answer_type" => "selection",
         "next_page" => 9,
         "is_optional" => true,
         "answer_settings" =>
         { "only_one_option" => "0",
           "selection_options" =>
           [{ "name" => "Option 1" }, { "name" => "Option 2" }, { "name" => "Option 3" }] },
         "created_at" => "2024-09-05T06:25:25.596Z",
         "updated_at" => "2024-09-05T06:25:25.596Z",
         "position" => 8,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] },
       { "id" => 9,
         "question_text" => "Multiple lines of text",
         "hint_text" => nil,
         "answer_type" => "text",
         "next_page" => nil,
         "is_optional" => true,
         "answer_settings" => { "input_type" => "long_text" },
         "created_at" => "2024-09-05T06:25:25.598Z",
         "updated_at" => "2024-09-05T06:25:25.598Z",
         "position" => 9,
         "page_heading" => nil,
         "guidance_markdown" => nil,
         "is_repeatable" => false,
         "routing_conditions" => [] }],
      "live_at" => "2024-09-05T06:25:25.637Z" }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/1/draft", req_headers, api_v1_response_data.merge(live_at: nil).to_json, 200
      mock.get "/api/v1/forms/1/live", req_headers, api_v1_response_data.to_json, 200
      mock.get "/api/v1/forms/1/archived", req_headers, api_v1_response_data.to_json, 200
      mock.get "/api/v1/forms/Alpha123/draft", req_headers, api_v1_response_data.merge(id: "Alpha123").to_json, 200
      mock.get "/api/v1/forms/99/draft", req_headers, nil, 404
    end
  end

  describe ".find_with_mode" do
    it "finds a form snapshot given a form id and document tag" do
      expect(described_class.find_with_mode(id: 1, mode: Mode.new("preview-draft"))).to be_truthy
    end

    it "returns a v1 API form snapshot" do
      form_snapshot = described_class.find_with_mode(id: 1, mode: Mode.new("preview-draft"))
      expect(form_snapshot).to be_a Form
      expect(form_snapshot.pages).to all be_a Page
    end

    it "raises an exception if the form does not exist" do
      expect {
        described_class.find_with_mode(id: 99, mode: Mode.new("preview-draft"))
      }.to raise_error(ActiveResource::ResourceNotFound)
    end

    context "when mode is live" do
      it "returns a live form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("live"))

        expect(form).to have_attributes(id: 1, name: "All question types form")
        expect(form).to be_live
      end
    end

    context "when mode is draft" do
      it "returns a draft form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("preview-draft"))

        expect(form).to have_attributes(id: 1, name: "All question types form")
        expect(form).not_to be_live
      end
    end

    context "when mode is archived" do
      it "returns an archived form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("preview-archived"))

        expect(form).to have_attributes(id: 1, name: "All question types form")
        expect(form).to be_live
      end
    end

    context "when mode is preview live" do
      it "returns a live form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("preview-live"))

        expect(form).to have_attributes(id: 1, name: "All question types form")
        expect(form).to be_live
      end
    end

    context "when validating the provided form id" do
      it "returns ResourceNotFound when the id contains non-alpha-numeric chars" do
        expect {
          described_class.find_with_mode(id: "<id>", mode: Mode.new("preview-draft"))
        }.to raise_error(ActiveResource::ResourceNotFound)
      end

      it "returns ResourceNotFound when the id is blank" do
        expect {
          described_class.find_with_mode(id: "", mode: Mode.new("preview-draft"))
        }.to raise_error(ActiveResource::ResourceNotFound)
      end

      it "returns the form when the id is alphanumeric" do
        form = described_class.find_with_mode(id: "Alpha123", mode: Mode.new("preview-draft"))

        expect(form).to have_attributes(id: "Alpha123", name: "All question types form")
      end
    end
  end
end
