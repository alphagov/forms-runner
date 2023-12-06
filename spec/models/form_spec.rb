require "rails_helper"

RSpec.describe Form, type: :model do
  let(:response_data) { { id: 1, name: "form name", submission_email: "user@example.com", start_page: 1 }.to_json }

  let(:pages_data) do
    [
      { id: 9, next_page: 10, answer_type: "date", question_text: "Question one" },
      { id: 10, answer_type: "address", question_text: "Question two" },
    ].to_json
  end

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/1", req_headers, response_data, 200
      mock.get "/api/v1/forms/1/pages", req_headers, pages_data, 200
    end
  end

  it "returns a simple form" do
    expect(described_class.find(1)).to have_attributes(id: 1, name: "form name", submission_email: "user@example.com")
  end

  describe "Getting the pages for a form" do
    it "returns the pages for a form" do
      pages = described_class.find(1).pages
      expect(pages.length).to eq(2)
      expect(pages[0]).to have_attributes(id: 9, next_page: 10, answer_type: "date", question_text: "Question one")
      expect(pages[1]).to have_attributes(id: 10, answer_type: "address", question_text: "Question two")
    end
  end

  describe "#live?" do
    context "when live_at is not set" do
      let(:response_data) { { id: 1, name: "form name", submission_email: "user@example.com", start_page: 1 }.to_json }

      it "raises an error" do
        expect { described_class.find(1).live? }.to raise_error(Date::Error)
      end
    end

    context "when no live_at is set to empty string" do
      let(:response_data) { { id: 1, name: "form name", live_at: "", submission_email: "user@example.com", start_page: 1 }.to_json }

      it "returns false" do
        expect(described_class.find(1).live?).to be false
      end
    end

    context "when live_at is a string which isn't a valid date" do
      let(:response_data) { { id: 1, name: "form name", live_at: "not a date!", submission_email: "user@example.com", start_page: 1 }.to_json }

      it "raises an error" do
        expect { described_class.find(1).live? }.to raise_error(Date::Error)
      end
    end

    context "when live_at is not a string" do
      let(:response_data) { { id: 1, name: "form name", live_at: 1, submission_email: "user@example.com", start_page: 1 }.to_json }

      it "raises an error" do
        expect { described_class.find(1).live? }.to raise_error(Date::Error)
      end
    end

    context "when live_at is a date in the future" do
      let(:response_data) { { id: 1, name: "form name", live_at: "2022-08-18 09:16:50Z", submission_email: "user@example.com", start_page: 1 }.to_json }

      it "returns false" do
        expect(described_class.find(1).live?("2022-01-01 10:00:00Z")).to be false
      end
    end

    context "when live_at is a date in the past" do
      let(:response_data) { { id: 1, name: "form name", live_at: "2022-08-18 09:16:50Z", submission_email: "user@example.com", start_page: 1 }.to_json }

      it "returns true" do
        expect(described_class.find(1).live?("2023-01-01 10:00:00Z")).to be true
      end
    end

    context "when dates are the same" do
      let(:response_data) { { id: 1, name: "form name", live_at: "2022-08-18 09:16:50Z", submission_email: "user@example.com", start_page: 1 }.to_json }

      it "returns false" do
        expect(described_class.find(1).live?("2022-08-18 09:16:50Z")).to be false
      end
    end
  end

  describe "what_happens_next" do
    let(:what_happens_next_markdown) { nil }
    let(:response_data) { { id: 1, name: "form name", submission_email: "user@example.com", start_page: 1, what_happens_next_markdown: }.to_json }

    context "when what_happens_next_markdown is nil" do
      it "returns nil" do
        expect(described_class.find(1).what_happens_next).to eq nil
      end
    end

    context "when what_happens_next_markdown has a value" do
      let(:what_happens_next_markdown) { "We’ll send you an email to let you know the outcome. Visit our [service status page](https://example.com) to see current response times.\n\nYou'll also need to:\n\n1. provide a certified copy of your documents\n2. make a payment" }

      it "returns the what_happens_next_markdown" do
        expect(described_class.find(1).what_happens_next).to eq what_happens_next_markdown
      end
    end
  end
end
