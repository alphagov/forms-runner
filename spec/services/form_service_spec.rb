require "rails_helper"

describe FormService do
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

    context "when id is alphanumeric and form exists in repository" do
      let(:form) { build :form,  id: "Alpha123", name: "form name", live_at: nil }

      before do
        mock_repository = class_double(FormRepository, find_with_mode: form)
        allow(FormService).to receive(:repository).and_return(mock_repository)
      end

      it "returns the form" do
        form = described_class.find_with_mode(id: "Alpha123", mode: Mode.new("preview-draft"))

        expect(form).to have_attributes(id: "Alpha123", name: "form name")
        expect(form.live?).to eq(false)
      end
    end
  end
end
