require "rails_helper"

RSpec.describe Forms::RemoveAnswerController, type: :request do
  let(:form) do
    build(:v2_form_document, :with_support, id: 2, start_page: 1, steps:)
  end

  let(:steps) { [first_step_in_form, second_step_in_form] }
  let(:is_optional) { false }
  let(:remove) { "yes" }

  let(:first_step_in_form) do
    build :v2_question_page_step,
          :with_text_settings,
          :with_repeatable,
          id: 1,
          next_step_id: 2,
          is_optional:
  end

  let(:second_step_in_form) do
    build :v2_question_page_step, :with_text_settings, id: 2
  end

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:api_url_suffix) { "/draft" }

  let(:stored_answers) do
    [{ text: "answer 1" }, { text: "answer 2" }]
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/#{form.id}#{api_url_suffix}", req_headers, form.to_json, 200
    end

    answer_store = instance_double(Store::SessionAnswerStore)
    allow(Store::SessionAnswerStore).to receive(:new).and_return(answer_store)
    allow(answer_store).to receive(:clear_stored_answer)
    allow(answer_store).to receive(:get_stored_answer).and_return(stored_answers)
    allow(answer_store).to receive(:save_step)
  end

  describe "GET #show" do
    it "renders the show template" do
      get "/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}/1/remove"
      expect(response).to render_template(:show)
    end

    it "initializes @remove_input" do
      get "/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}/1/remove"
      expect(assigns(:remove_input)).to be_a(RemoveInput)
    end
  end

  describe "DELETE #delete" do
    context "with valid params" do
      it "redirects to add another answer" do
        delete "/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}/1/remove", params: { remove_input: { remove: } }
        expect(response).to redirect_to("/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}/add-another-answer")
      end

      context "when not removing answer" do
        let(:remove) { "no" }

        it "redirects to add another answer" do
          delete "/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}/1/remove", params: { remove_input: { remove: } }
          expect(response).to redirect_to("/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}/add-another-answer")
        end
      end
    end

    context "with invalid params" do
      let(:remove) { "invalid" }

      it "renders the show template" do
        delete "/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}/1/remove", params: { remove_input: { remove: } }
        expect(response).to render_template(:show)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when removing an answer for an optional question with no remaining answers" do
      let(:stored_answers) { [{ text: "answer 1" }] }
      let(:is_optional) { true }

      it "redirects to the next question page" do
        delete "/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}/1/remove", params: { remove_input: { remove: } }
        expect(response).to redirect_to("/preview-draft/#{form.id}/#{form.form_slug}/#{first_step_in_form.id}")
      end
    end
  end
end
