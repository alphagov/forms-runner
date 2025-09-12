require "rails_helper"

RSpec.describe Forms::AddAnotherAnswerController, type: :request do
  let(:form) do
    build(:v2_form_document, :with_support, id: 2, start_page: 1, steps:)
  end

  let(:steps) { [first_step_in_form, second_step_in_form] }

  let(:first_step_in_form) do
    build :v2_question_page_step,
          :with_text_settings,
          id: 1,
          next_step_id: 2,
          is_optional: false,
          is_repeatable: true
  end

  let(:second_step_in_form) do
    build :v2_question_page_step, :with_text_settings, id: 2
  end

  let(:req_headers) { { "Accept" => "application/json" } }

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
  end

  describe "GET #show" do
    before do
      get add_another_answer_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: first_step_in_form.id)
    end

    it "renders the show template" do
      expect(response).to render_template(:show)
    end

    it "assigns @rows" do
      expect(assigns(:rows).count).to eq 2
    end

    it "adds the change and remove links to each row" do
      expect(assigns(:rows).first[:actions].first[:text]).to eq("Change")
      expect(assigns(:rows).first[:actions].second[:text]).to eq("Remove")
      expect(response.body).to include(form_remove_answer_path(form.id, form.form_slug, first_step_in_form.id, answer_index: 1, changing_existing_answer: nil))
    end

    it "initializes @add_another_answer_input" do
      expect(assigns(:add_another_answer_input)).to be_a(AddAnotherAnswerInput)
    end
  end

  describe "POST #save" do
    before do
      post add_another_answer_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: first_step_in_form.id), params:
    end

    context "with valid params" do
      context "when adding another answer" do
        let(:params) { { add_another_answer_input: { add_another_answer: "yes" } } }

        it "redirects to first page to add another" do
          expect(response).to redirect_to(form_page_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: first_step_in_form.id, answer_index: 3))
        end
      end

      context "when not adding another answer" do
        let(:params) { { add_another_answer_input: { add_another_answer: "no" } } }

        it "redirects to next page" do
          expect(response).to redirect_to(form_page_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: second_step_in_form.id))
        end
      end
    end

    context "with invalid params" do
      let(:params) { { add_another_answer_input: { add_another_answer: "" } } }

      it "renders the show template" do
        expect(response).to render_template(:show)
      end

      it "assigns @rows" do
        expect(assigns(:rows).count).to be_present
      end
    end

    context "with the maximum number of answers" do
      let(:stored_answers) { Array.new(RepeatableStep::MAX_ANSWERS) { |i| { text: i.to_s } } }
      let(:params) { { add_another_answer_input: { add_another_answer: "yes" } } }

      it "renders the show template with an error" do
        post add_another_answer_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: first_step_in_form.id), params: { add_another_answer_input: { add_another_answer: "yes" } }
        expect(response).to render_template(:show)
        expect(response.body).to include("You cannot add another answer")
      end
    end
  end

  describe "redirect_if_not_repeating" do
    context "when step is not RepeatableStep" do
      it "redirects to form_page when not changing existing answer" do
        get add_another_answer_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: second_step_in_form.id)
        expect(response).to redirect_to(form_page_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: second_step_in_form.id))
      end

      it "redirects to form_change_answer_path when changing existing answer" do
        get change_add_another_answer_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: second_step_in_form.id)
        expect(response).to redirect_to(form_change_answer_path(mode: "preview-draft", form_id: form.id, form_slug: form.form_slug, page_slug: second_step_in_form.id))
      end
    end
  end
end
