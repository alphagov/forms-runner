require "rails_helper"

RSpec.describe Page, type: :model do
  it "has a valid factory" do
    page = build :page
    expect(page).to be_valid
  end

  describe "#answer_settings" do
    it "returns an empty object for answer_settings when it's not present" do
      page = described_class.new
      expect(page).to have_attributes(answer_settings: {})
    end

    it "returns an answer settings object for answer_settings when present" do
      page = described_class.new(answer_settings: { only_one_option: "true" })
      expect(page.answer_settings.attributes).to eq({ "only_one_option" => "true" })
    end
  end

  describe "#repeatable?" do
    it "returns false when attribute does not exist" do
      page = described_class.new
      expect(page.repeatable?).to be false
    end

    it "returns false when attribute is false" do
      page = described_class.new is_repeatable: false
      expect(page.repeatable?).to be false
    end

    it "returns true when attribute is true" do
      page = described_class.new is_repeatable: true
      expect(page.repeatable?).to be true
    end
  end

  describe "API call" do
    let(:form_snapshot) do
      {
        id: 2,
        pages: [page],
      }
    end

    let(:page) do
      {
        id: 1,
        question_text: "Question text",
        answer_type: "date",
      }
    end

    let(:req_headers) do
      {
        "X-API-Token" => Settings.forms_api.auth_key,
        "Accept" => "application/json",
      }
    end

    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v1/forms/2/draft", req_headers, form_snapshot.to_json, 200
        mock.get "/api/v1/forms/2/pages/1", req_headers, page.to_json, 200
      end
    end

    it "models the pages of a form as page records" do
      expect(Form.find_draft(2).pages.first).to have_attributes(
        id: 1, question_text: "Question text", answer_type: "date",
      )
    end

    it "raises a deprecation warning if a page is requested" do
      expect {
        described_class.find(1, params: { form_id: 2 })
      }.to raise_error(ActiveSupport::DeprecationException)
    end
  end
end
