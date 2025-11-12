require "rails_helper"

RSpec.describe FillerSession do
  subject(:filler_session) { described_class.new(session, form_id:, mode:) }

  let(:session) { {} }
  let(:form_id) { 100 }
  let(:mode) { Mode.new("preview-draft") }

  let(:document_json) { build(:v2_form_document, :ready_for_live, form_id:).as_json }

  let(:req_headers) { { "Accept" => "application/json" } }

  context "when form exists" do
    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v2/forms/#{form_id}/#{mode.tag}", req_headers, document_json.to_json, 200
      end
    end

    describe "#form_document" do
      it "returns a form document" do
        expect(filler_session.form_document).to eq document_json
      end

      it "gets the form document from the API" do
        expect {
          filler_session.form_document
        }.to change(ActiveResource::HttpMock.requests, :length).by(1)
      end
    end

    describe "#form" do
      it "returns a form object" do
        expect(filler_session.form).to be_a Form
      end

      it "has the data from the form document" do
        expect(filler_session.form.id).to eq form_id
      end

      it "gets the data from the API" do
        expect {
          filler_session.form
        }.to change(ActiveResource::HttpMock.requests, :length).by(1)
      end
    end

    describe "#context" do
      it "returns a flow context object" do
        expect(filler_session.context).to be_a Flow::Context
      end

      it "uses the form from the filler session" do
        expect(filler_session.context.form).to eq filler_session.form
      end
    end

    context "when form document is already in session store" do
      let(:session_store_spy) do
        Store::SessionFormDocumentStore.new(
          session, form_id, mode.tag,
        )
      end

      before do
        allow(Store::SessionFormDocumentStore).to receive(:new).with(session, form_id, mode.tag).and_return(session_store_spy)
        allow(session_store_spy).to receive(:get_stored).and_call_original
        session_store_spy.save(document_json)
      end

      describe "#form_document" do
        it "returns a form document" do
          expect(filler_session.form_document).to eq document_json
        end

        it "gets the form document from the session store" do
          filler_session.form_document
          expect(session_store_spy).to have_received(:get_stored)
        end

        it "does not get the form document from the API" do
          expect {
            filler_session.form_document
          }.not_to change(ActiveResource::HttpMock.requests, :length)
        end
      end

      describe "#form" do
        it "returns a form object" do
          expect(filler_session.form).to be_a Form
        end

        it "has the data from the form document" do
          expect(filler_session.form.id).to eq form_id
        end

        it "gets the form data from the session store" do
          filler_session.form
          expect(session_store_spy).to have_received(:get_stored)
        end

        it "does not get the data from the API" do
          expect {
            filler_session.form
          }.not_to change(ActiveResource::HttpMock.requests, :length)
        end
      end

      describe "#context" do
        it "returns a flow context object" do
          expect(filler_session.context).to be_a Flow::Context
        end

        it "uses the form from the filler session" do
          expect(filler_session.context.form).to eq filler_session.form
        end

        it "gets the form data from the session store" do
          filler_session.context
          expect(session_store_spy).to have_received(:get_stored)
        end

        it "does not get the data from the API" do
          expect {
            filler_session.context
          }.not_to change(ActiveResource::HttpMock.requests, :length)
        end
      end
    end
  end

  context "when form does not exist" do
    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v2/forms/#{form_id}/#{mode.tag}", req_headers, nil, 404
      end
    end

    describe "#context" do
      it "raises an error" do
        expect { filler_session.context }.to raise_error ActiveResource::ResourceNotFound
      end
    end

    describe "#form" do
      it "raises an error" do
        expect { filler_session.context }.to raise_error ActiveResource::ResourceNotFound
      end
    end

    describe "#form_document" do
      it "raises an error" do
        expect { filler_session.context }.to raise_error ActiveResource::ResourceNotFound
      end
    end
  end
end
