require "rails_helper"

RSpec.describe Store::SessionFormDocumentStore do
  subject(:form_document_store) { described_class.new(store, form_id, tag) }

  let(:store) { {} }
  let(:form_id) { 1 }
  let(:tag) { :live }

  let(:form_document) { build(:v2_form_document, form_id:) }

  it "stores a form document" do
    form_document_store.save(form_document)
    result = form_document_store.get_stored
    expect(result).to eq form_document
  end

  describe "#clear" do
    before do
      form_document_store.save(form_document)
    end

    it "clears the form document" do
      expect(form_document_store.get_stored).to eq form_document
      form_document_store.clear
      expect(form_document_store.get_stored).to be_nil
    end

    it "does not error if removing a form document which doesn't exist in the store" do
      form_document.clear
      expect { form_document_store.clear }.not_to raise_error
    end

    it "does not remove form documents for other forms from the store" do
      other_form_document = build(:v2_form_document, form_id: 2)
      other_form_document_store = described_class.new(store, 2, tag)
      other_form_document_store.save(other_form_document)

      form_document_store.clear

      expect(other_form_document_store.get_stored).to eq other_form_document
    end

    it "does not remove other form documents from the store" do
      other_form_document = build(:v2_form_document, form_id:)
      other_form_document_store = described_class.new(store, 2, :preview)
      other_form_document_store.save(other_form_document)

      form_document_store.clear

      expect(other_form_document_store.get_stored).to eq other_form_document
    end
  end
end
