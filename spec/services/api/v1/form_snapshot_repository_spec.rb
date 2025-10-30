require "rails_helper"

RSpec.describe Api::V1::FormSnapshotRepository do
  let(:req_headers) { { "Accept" => "application/json" } }

  let(:form_id) { 1 }
  let(:api_v2_response_data) { JSON.load_file("spec/fixtures/all_question_types_form.json") }

  describe ".find_with_mode" do
    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v2/forms/1/draft", req_headers, api_v2_response_data.merge(name: "Draft form").to_json, 200
        mock.get "/api/v2/forms/1/live", req_headers, api_v2_response_data.merge(name: "Live form").to_json, 200
        mock.get "/api/v2/forms/1/archived", req_headers, api_v2_response_data.merge(name: "Archived form").to_json, 200
        mock.get "/api/v2/forms/2/live", req_headers, nil, 404
        mock.get "/api/v2/forms/2/archived", req_headers, api_v2_response_data.to_json, 200
        mock.get "/api/v2/forms/Alpha123/draft", req_headers, api_v2_response_data.merge("id": "Alpha123").to_json, 200
        mock.get "/api/v2/forms/99/draft", req_headers, nil, 404
      end
    end

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

        expect(form).to have_attributes(id: "1", name: "Live form")
      end
    end

    context "when mode is draft" do
      it "returns a draft form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("preview-draft"))

        expect(form).to have_attributes(id: "1", name: "Draft form")
      end
    end

    context "when mode is archived" do
      it "returns an archived form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("preview-archived"))

        expect(form).to have_attributes(id: "1", name: "Archived form")
      end
    end

    context "when mode is preview live" do
      it "returns a live form" do
        form = described_class.find_with_mode(id: 1, mode: Mode.new("preview-live"))

        expect(form).to have_attributes(id: "1", name: "Live form")
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

  describe ".find_archived" do
    let(:form_id) { 1 }
    let(:response_data) { api_v2_response_data.to_json }
    let(:status) { 200 }

    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v2/forms/#{form_id}/archived", req_headers, response_data, status
      end
    end

    context "when a form has been archived" do
      it "returns an archived form" do
        form = described_class.find_archived(id: form_id)

        expect(form).to have_attributes(id: form_id.to_s, name: "All question types form")
      end
    end

    context "when a form has not been archived" do
      let(:response_data) { nil }
      let(:status) { 404 }

      it "raises ActiveResource::ResourceNotFound" do
        expect { described_class.find_archived(id: form_id) }.to raise_error(ActiveResource::ResourceNotFound)
      end
    end

    context "when the form id contains non-alpha-numeric chars" do
      let(:form_id) { "<id>" }

      it "returns ResourceNotFound when the id contains non-alpha-numeric chars" do
        expect {
          described_class.find_archived(id: form_id)
        }.to raise_error(ActiveResource::ResourceNotFound)
      end
    end

    context "when the form id is blank" do
      let(:form_id) { "" }

      it "returns ResourceNotFound when the id is blank" do
        expect {
          described_class.find_archived(id: form_id)
        }.to raise_error(ActiveResource::ResourceNotFound)
      end
    end

    context "when the form doesn't exist" do
      let(:form_id) { 99 }
      let(:response_data) { nil }
      let(:status) { 404 }

      it "raises an exception if the form does not exist" do
        expect {
          described_class.find_archived(id: form_id)
        }.to raise_error(ActiveResource::ResourceNotFound)
      end
    end
  end
end
