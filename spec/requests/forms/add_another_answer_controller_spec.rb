require "rails_helper"

RSpec.describe Forms::AddAnotherAnswerController, type: :request do
  let(:form) do
    build(:form, :with_support, id: 2, start_page: 1, pages:)
  end

  let(:pages) { [first_page_in_form, second_page_in_form] }

  let(:first_page_in_form) do
    build :page,
          :with_text_settings,
          :with_repeatable,
          id: 1,
          next_page: 2,
          is_optional: false
  end

  let(:second_page_in_form) do
    build :page, :with_text_settings, id: 2
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
      mock.get "/api/v1/forms/#{form.id}#{api_url_suffix}", req_headers, form.to_json, 200
    end

    form_context = instance_double(Flow::FormContext)
    allow(Flow::FormContext).to receive(:new).and_return(form_context)
    allow(form_context).to receive(:clear_stored_answer)
    allow(form_context).to receive(:get_stored_answer).and_return(stored_answers)
  end

  describe "GET #show" do
    it "renders the show template" do
      get "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer"
      expect(response).to render_template(:show)
    end

    it "assigns @rows" do
      get "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer"
      expect(assigns(:rows).count).to eq 2
    end

    it "adds the change and remove links to each row" do
      get "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer"
      expect(assigns(:rows).first[:actions].first[:text]).to eq("Change")
      expect(assigns(:rows).first[:actions].second[:text]).to eq("Remove")
      expect(response.body).to include(form_remove_answer_path(form.id, form.form_slug, first_page_in_form.id, answer_index: 1, changing_existing_answer: nil))
    end

    it "initializes @add_another_answer_input" do
      get "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer"
      expect(assigns(:add_another_answer_input)).to be_a(AddAnotherAnswerInput)
    end
  end

  describe "POST #save" do
    context "with valid params" do
      context "when adding another answer" do
        it "redirects to first page to add another" do
          post "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer", params: { add_another_answer_input: { add_another_answer: "yes" } }
          expect(response).to redirect_to("/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/3")
        end
      end

      context "when not adding another answer" do
        it "redirects to next page" do
          post "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer", params: { add_another_answer_input: { add_another_answer: "no" } }
          expect(response).to redirect_to("/preview-draft/#{form.id}/#{form.form_slug}/#{second_page_in_form.id}")
        end
      end
    end

    context "with invalid params" do
      it "renders the show template" do
        post "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer", params: { add_another_answer_input: { add_another_answer: "" } }
        expect(response).to render_template(:show)
      end

      it "assigns @rows" do
        post "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer", params: { add_another_answer_input: { add_another_answer: "" } }
        expect(assigns(:rows).count).to be_present
      end
    end

    context "with the maximum number of answers" do
      let(:stored_answers) { Array.new(RepeatableStep::MAX_ANSWERS) { |i| { text: i.to_s } } }

      it "renders the show template with an error" do
        post "/preview-draft/#{form.id}/#{form.form_slug}/#{first_page_in_form.id}/add-another-answer", params: { add_another_answer_input: { add_another_answer: "yes" } }
        expect(response).to render_template(:show)
        expect(response.body).to include("You cannot add another answer")
      end
    end
  end

  describe "redirect_if_not_repeating" do
    context "when step is not RepeatableStep" do
      it "redirects to form_page when not changing existing answer" do
        get "/preview-draft/#{form.id}/#{form.form_slug}/#{second_page_in_form.id}/add-another-answer"
        expect(response).to redirect_to("/preview-draft/#{form.id}/#{form.form_slug}/#{second_page_in_form.id}")
      end

      it "redirects to form_change_answer_path when changing existing answer" do
        get "/preview-draft/#{form.id}/#{form.form_slug}/#{second_page_in_form.id}/add-another-answer/change"
        expect(response).to redirect_to("/preview-draft/#{form.id}/#{form.form_slug}/#{second_page_in_form.id}/change")
      end
    end
  end
end
