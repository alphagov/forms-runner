require "rails_helper"

# rubocop:disable RSpec/AnyInstance
RSpec.describe Forms::PageController, type: :request do
  let(:timestamp_of_request) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }

  let(:form_data) do
    build(:v2_form_document, :with_support,
          id: 2,
          live_at:,
          start_page: 1,
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          what_happens_next_markdown: "Good things come to those that wait",
          declaration_text: "agree to the declaration",
          steps: steps_data)
  end
  let(:live_at) { "2022-08-18 09:16:50 +0100" }

  let(:first_step_in_form) do
    build :v2_question_page_step, :with_text_settings,
          id: 1,
          next_step_id: 2,
          is_optional: false
  end

  let(:second_step_in_form) do
    build :v2_question_page_step, :with_text_settings,
          id: 2,
          is_optional:
  end

  let(:page_with_routing) do
    build :v2_question_page_step, :with_selections_settings,
          id: 1,
          next_step_id: 2,
          routing_conditions: [DataStruct.new(id: 1, routing_page_id: 1, check_page_id: 1, goto_page_id: 3, answer_value: "Option 1", validation_errors:)],
          is_optional: false
  end

  let(:steps_data) { [first_step_in_form, second_step_in_form] }

  let(:is_optional) { false }

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:api_url_suffix) { "/live" }
  let(:mode) { "form" }

  let(:output) { StringIO.new }
  let(:logger) { ActiveSupport::Logger.new(output) }

  before do
    # Intercept the request logs so we can do assertions on them
    allow(Lograge).to receive(:logger).and_return(logger)

    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/2#{api_url_suffix}", req_headers, form_data.to_json, 200
    end
  end

  context "when setting logging context" do
    let(:page_id) { 101 }
    let(:form_data) do
      build(:form, :with_support,
            id: 200,
            live_at:,
            start_page: page_id,
            declaration_text: "agree to the declaration",
            steps: [
              build(:v2_question_page_step, :with_text_settings,
                    id: page_id,
                    position: 1,
                    is_optional: false),
            ])
    end

    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v2/forms/200#{api_url_suffix}", req_headers, form_data.to_json, 200
      end

      get form_page_path(200, form_data.form_slug, page_id, mode:)
    end

    it "adds the page ID to the instrumentation payload" do
      expect(log_lines[0]["page_id"]).to eq(page_id.to_s)
    end

    it "adds the question_number to the instrumentation payload" do
      expect(log_lines[0]["question_number"]).to eq(1)
    end

    it "adds the answer_type to the instrumentation payload" do
      expect(log_lines[0]["answer_type"]).to eq("text")
    end
  end

  shared_examples "ordered steps" do
    it "redirects to first page if second request before first complete" do
      get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2)
      expect(response).to redirect_to(form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1))
    end
  end

  shared_examples "page with footer" do
    it "Displays the privacy policy link on the page" do
      get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
      expect(response.body).to include("Privacy")
    end

    it "Displays the accessibility statement link on the page" do
      get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
      expect(response.body).to include("Accessibility statement")
    end

    it "Displays the Cookies link on the page" do
      get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
      expect(response.body).to include("Cookies")
    end
  end

  shared_examples "question page" do
    it "Returns a 200" do
      get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
      expect(response).to have_http_status(:ok)
    end

    it "Returns the correct X-Robots-Tag header" do
      get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    end

    it "Displays the question text on the page" do
      get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
      expect(response.body).to include(form_data.steps.first.data.question_text)
    end

    context "with a page that has a previous page" do
      it "Displays a link to the previous page" do
        allow_any_instance_of(Flow::Context).to receive(:can_visit?).and_return(true)
        allow_any_instance_of(Flow::Context).to receive(:previous_step).and_return(OpenStruct.new(page_id: 1))
        get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2)
        expect(response.body).to include(form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1))
      end
    end

    context "with a change answers page" do
      it "Displays a back link to the check your answers page" do
        get form_change_answer_path(2, form_data.form_slug, 1, mode:)
        expect(response.body).to include(check_your_answers_path(2, form_data.form_slug, mode:))
      end

      it "Passes the changing answers parameter in its submit request" do
        get form_change_answer_path(2, form_data.form_slug, 1, mode:)
        expect(response.body).to include(save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1, changing_existing_answer: true, answer_index: 1))
      end
    end

    context "with no questions answered" do
      it "redirects if a later page is requested" do
        get check_your_answers_path(2, form_data.form_slug, mode:)
        expect(response).to have_http_status(:found)
        expect(response.location).to eq(form_page_url(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1))
      end
    end
  end

  describe "#show" do
    context "with preview mode on" do
      let(:api_url_suffix) { "/draft" }
      let(:mode) { "preview-draft" }

      it_behaves_like "ordered steps"

      it_behaves_like "page with footer"

      it_behaves_like "question page"
    end

    context "with preview mode off" do
      let(:api_url_suffix) { "/live" }
      let(:mode) { "form" }

      [
        "/form/2/1/check_your_answers_trailing",
        "/form/2/1/leading_check_your_answers",
        "/form/2/1/1/check_your_answers",
        "/form/2/1/1/ChEck_YouR_aNswers",
        "/form/2/1/1/%20123",
        "/form/2/1/__",
        "/form/2/1/debug.cgi",
        "/form/2/1/hsqldb%0A",
        "/form/2/1/index_sso.php",
        "/form/2/1/setup.php",
        "/form/2/1/test.cgi",
        "/form/2/1/x",
      ].each do |path|
        context "with an invalid URL: #{path}" do
          before do
            allow(Sentry).to receive(:capture_exception)
            get path
          end

          it "returns a 404" do
            expect(response).to have_http_status(:not_found)
          end

          it "does not send an expception to sentry" do
            expect(Sentry).not_to have_received(:capture_exception)
          end
        end
      end

      it_behaves_like "ordered steps"

      it_behaves_like "page with footer"

      it_behaves_like "question page"

      context "and a form has a live_at value in the future" do
        let(:live_at) { "2023-01-01 09:00:00 +0100" }

        it "returns 404" do
          travel_to timestamp_of_request do
            get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
          end

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when viewing a live form with no routing_conditions" do
      let(:mode) { "preview-live" }

      let(:first_step_in_form) do
        step_without_routing_conditions = attributes_for(:v2_question_page_step, :with_text_settings,
                                                         id: 1,
                                                         next_step_id: 2,
                                                         is_optional: false).except(:routing_conditions)

        DataStruct.new(step_without_routing_conditions)
      end

      it "Returns a 200" do
        get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when page has routing conditions" do
      let(:first_step_in_form) do
        page_with_routing
      end

      let(:validation_errors) { [] }

      let(:second_step_in_form) do
        build :page, :with_text_settings,
              id: 2,
              next_step_id: 3,
              is_optional:
      end

      let(:third_step_in_form) do
        build :page, :with_text_settings,
              id: 3,
              is_optional:
      end

      let(:pages_data) { [third_step_in_form, first_step_in_form, second_step_in_form] }

      let(:api_url_suffix) { "/draft" }
      let(:mode) { "preview-draft" }

      context "when the routing has a cannot_have_goto_page_before_routing_page error" do
        let(:pages_data) { [first_step_in_form, second_step_in_form, third_step_in_form] }
        let(:validation_errors) { [{ name: "cannot_have_goto_page_before_routing_page" }] }

        it "returns a 422 response" do
          get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "shows the error page" do
          get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
          link_url = "#{Settings.forms_admin.base_url}/forms/2/pages/1/routes"
          question_number = first_step_in_form.position
          expect(response.body).to include(I18n.t("goto_page_routing_error.cannot_have_goto_page_before_routing_page.body_html", link_url:, question_number:))
        end

        it "logs an error event" do
          expect(EventLogger).to receive(:log_page_event).with("goto_page_before_routing_page_error", first_step_in_form.data.question_text, nil)
          get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        end

        context "when the route is a secondary skip" do
          let(:page_with_secondary_skip) do
            build :v2_question_page_step, :with_selections_settings,
                  id: 4,
                  next_step_id: nil,
                  skip_to_end: true,
                  routing_conditions: [DataStruct.new(id: 2, routing_page_id: 4, check_page_id: 1, goto_page_id: 3, validation_errors:)],
                  is_optional: false
          end

          let(:steps_data) { [third_step_in_form, first_step_in_form, second_step_in_form, page_with_secondary_skip] }

          it "returns a 422 response" do
            get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 4)
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "shows the error page" do
            get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 4)
            link_url = "#{Settings.forms_admin.base_url}/forms/2/pages/1/routes"
            question_number = first_step_in_form.position
            expect(response.body).to include(I18n.t("goto_page_routing_error.cannot_have_goto_page_before_routing_page.body_html", link_url:, question_number:))
          end
        end
      end

      context "when the routing has a goto_page which does not exist" do
        let(:pages_data) { [first_step_in_form, second_step_in_form, third_step_in_form] }
        let(:validation_errors) { [{ name: "goto_page_doesnt_exist" }] }

        it "returns a 422 response" do
          get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "shows the error page" do
          get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
          link_url = "#{Settings.forms_admin.base_url}/forms/2/pages/1/routes"
          question_number = first_step_in_form.position
          expect(response.body).to include(I18n.t("goto_page_routing_error.goto_page_doesnt_exist.body_html", link_url:, question_number:))
        end

        it "logs an error event" do
          expect(EventLogger).to receive(:log_page_event).with("goto_page_doesnt_exist_error", first_step_in_form.data.question_text, nil)
          get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        end
      end
    end

    context "when page is repeatable" do
      let(:mode) { "form" }

      let(:first_step_in_form) { build :v2_question_page_step, :with_repeatable, id: 1, next_step_id: second_step_in_form.id }

      it "shows the page as normal when there are no stored answers" do
        get form_page_path(mode:, form_id: form_data.id, form_slug: form_data.form_slug, page_slug: first_step_in_form.id, answer_index: 1)
        expect(response).to have_http_status(:ok)
      end

      it "returns 404 when given an invalid answer_index" do
        get form_page_path(mode:, form_id: form_data.id, form_slug: form_data.form_slug, page_slug: first_step_in_form.id, answer_index: 12)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the page is a file upload question" do
      let(:first_step_in_form) do
        build :v2_question_page_step,
              id: 1,
              next_step_id: 2,
              answer_type: "file",
              is_optional: true
      end

      before do
        allow(Flow::Context).to receive(:new).and_wrap_original do |original_method, *args|
          context_spy = original_method.call(form: args[0][:form], store:)
          context_spy
        end
        get form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
      end

      context "when the question has already been answered" do
        let(:store) do
          {
            answers: {
              form_data.id.to_s => {
                first_step_in_form.id.to_s => {
                  "original_filename" => "foo.png",
                  "uploaded_file_key" => "bar",
                },
              },
            },
          }
        end

        it "redirects to the review file route" do
          expect(response).to redirect_to review_file_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        end
      end

      context "when the question hasn't been answered" do
        let(:store) { { answers: {} } }

        it "renders the show page template" do
          expect(response).to render_template("forms/page/show")
        end
      end
    end
  end

  describe "#save" do
    before do
      allow_any_instance_of(Flow::Context).to receive(:clear_submission_details)
    end

    shared_examples "for validating answer" do
      context "when the form is invalid" do
        before do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "" }, changing_existing_answer: false }
        end

        it "renders the show page template" do
          expect(response).to render_template("forms/page/show")
        end

        it "returns 422" do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "adds validation_errors logging attribute" do
          expect(log_lines[0]["validation_errors"]).to eq(["text: blank"])
        end
      end
    end

    shared_examples "for redirecting after saving answer" do
      it "Redirects to the next page" do
        post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2))
      end

      it "does not add validation_errors logging attribute" do
        post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        expect(log_lines[0].keys).not_to include("validation_errors")
      end

      context "when changing an existing answer" do
        it "Redirects to the check your answers page" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
          expect(response).to redirect_to(check_your_answers_path(2, form_data.form_slug, mode:))
        end
      end

      context "with the final page" do
        it "Redirects to the check your answers page" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
          expect(response).to redirect_to(check_your_answers_path(2, form_data.form_slug, mode:))
        end
      end
    end

    context "with preview mode on" do
      let(:api_url_suffix) { "/draft" }
      let(:mode) { "preview-draft" }

      include_examples "for validating answer"
      include_examples "for redirecting after saving answer"

      context "when changing an existing answer" do
        it "does not log the change_answer_page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
        end
      end

      context "with the first page" do
        it "does not log the first_page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" } }
        end

        it "clears the submission reference from the session" do
          expect_any_instance_of(Flow::Context).to receive(:clear_submission_details).once
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" } }
        end
      end

      context "with a subsequent page" do
        it "does not log the page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
        end

        it "does not clear the submission reference from the session" do
          expect_any_instance_of(Flow::Context).not_to receive(:clear_submission_details)
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
        end
      end

      context "and a form has a live_at value in the future" do
        let(:live_at) { "2023-01-01 09:00:00 +0100" }

        it "does not return 404" do
          travel_to timestamp_of_request do
            post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
          end
          expect(response).not_to have_http_status(:not_found)
        end
      end
    end

    context "with preview mode off" do
      let(:api_url_suffix) { "/live" }
      let(:mode) { "form" }

      include_examples "for validating answer"
      include_examples "for redirecting after saving answer"

      context "when changing an existing answer" do
        it "Logs the change_answer_page_save event" do
          expect(EventLogger).to receive(:log_page_event).with("change_answer_page_save", first_step_in_form.data.question_text, nil)
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
        end
      end

      context "with the first page" do
        it "Logs the first_page_save event" do
          expect(EventLogger).to receive(:log_page_event).with("first_page_save", first_step_in_form.data.question_text, nil)
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" } }
        end
      end

      context "with a subsequent page" do
        it "Logs the page_save event" do
          expect(EventLogger).to receive(:log_page_event).with("page_save", second_step_in_form.data.question_text, nil)
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
        end
      end

      context "with an subsequent optional page" do
        let(:is_optional) { true }

        context "when an optional question is completed" do
          it "Logs the optional_save event with skipped_question as true" do
            expect(EventLogger).to receive(:log_page_event).with("optional_save", second_step_in_form.data.question_text, true)
            post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "" } }
          end
        end

        context "when an optional question is skipped" do
          it "Logs the optional_save event with skipped_question as false" do
            expect(EventLogger).to receive(:log_page_event).with("optional_save", second_step_in_form.data.question_text, false)
            post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
          end
        end
      end
    end

    context "when page has routing conditions" do
      let(:first_step_in_form) do
        page_with_routing
      end

      let(:validation_errors) { [] }

      let(:second_step_in_form) do
        build :page, :with_text_settings,
              id: 2,
              next_step_id: 3,
              is_optional:
      end

      let(:third_step_in_form) do
        build :page, :with_text_settings,
              id: 3,
              is_optional:
      end

      let(:pages_data) { [first_step_in_form, second_step_in_form, third_step_in_form] }

      let(:api_url_suffix) { "/draft" }
      let(:mode) { "preview-draft" }

      it "redirects to the goto page if answer value matches condition" do
        post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { selection: "Option 1" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 3))
      end

      context "when the answer_value does not match the condition" do
        it "redirects to the next page in the journey" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { selection: "Option 2" }, changing_existing_answer: false }
          expect(response).to redirect_to(form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2))
        end
      end

      context "when the routing has a cannot_have_goto_page_before_routing_page error" do
        let(:pages_data) { [first_step_in_form, second_step_in_form, third_step_in_form] }
        let(:validation_errors) { [{ name: "cannot_have_goto_page_before_routing_page" }] }

        it "returns a 422 response" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { selection: "Option 2" }, changing_existing_answer: false }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "shows the error page" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { selection: "Option 2" }, changing_existing_answer: false }
          link_url = "#{Settings.forms_admin.base_url}/forms/2/pages/1/routes"
          question_number = first_step_in_form.position
          expect(response.body).to include(I18n.t("goto_page_routing_error.cannot_have_goto_page_before_routing_page.body_html", link_url:, question_number:))
        end
      end

      # TODO: Need to add test to check how changing an existing routing answer value would work. Better off as a feature spec which we dont have.
    end

    context "when page is repeatable" do
      let(:first_step_in_form) { build :v2_question_page_step, :with_repeatable, id: 1, next_step_id: second_step_in_form.id }

      it "redirects to the add another answer page when given valid answer" do
        post save_form_page_path(mode:, form_id: form_data.id, form_slug: form_data.form_slug, page_slug: first_step_in_form.id, params: { question: { number: 12 } })
        expect(response).to redirect_to(add_another_answer_path(mode:, form_id: form_data.id, form_slug: form_data.form_slug, page_slug: first_step_in_form.id))
      end

      it "shows 404 if an invalid answer_index is given" do
        post save_form_page_path(mode:, form_id: form_data.id, form_slug: form_data.form_slug, page_slug: first_step_in_form.id, answer_index: 3, params: { question: { number: 12 } })
        expect(response).to have_http_status(:not_found)
      end

      context "and is optional" do
        let(:first_step_in_form) { build :v2_question_page_step, :with_repeatable, is_optional: true, id: 1, next_step_id: second_step_in_form.id }

        it "redirects to the next page when not given an answer" do
          post save_form_page_path(mode:, form_id: form_data.id, form_slug: form_data.form_slug, page_slug: first_step_in_form.id, params: { question: { number: nil } })
          expect(response).to redirect_to(form_page_path(mode:, form_id: form_data.id, form_slug: form_data.form_slug, page_slug: second_step_in_form.id))
        end
      end
    end

    context "when the page is a file upload question" do
      let(:first_step_in_form) do
        build :v2_question_page_step,
              id: 1,
              next_step_id: 2,
              answer_type: "file",
              is_optional: true
      end

      context "when a file was uploaded" do
        let(:mock_s3_client) { Aws::S3::Client.new(stub_responses: true) }
        let(:tempfile) { Tempfile.new(%w[temp-file .jpeg]) }
        let(:content_type) { "image/jpeg" }
        let(:question) { { file: Rack::Test::UploadedFile.new(tempfile.path, content_type) } }

        before do
          File.write(tempfile, "some content")
          allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
          allow(mock_s3_client).to receive(:get_object_tagging).and_return({ tag_set: [{ key: "GuardDutyMalwareScanStatus", value: "NO_THREATS_FOUND" }] })
        end

        after do
          tempfile.unlink
        end

        it "redirects to the review file route" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: }
          expect(response).to redirect_to review_file_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        end

        it "displays a success banner" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: }

          expect(flash[:success]).to eq(I18n.t("banner.success.file_uploaded"))
        end

        it "adds answer_metadata logging attribute" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: }
          expect(log_lines[0]["answer_metadata"]).to eq({
            "file_size_in_bytes" => tempfile.size,
            "file_type" => content_type,
          })
        end

        context "when changing an existing answer" do
          it "includes the changing_existing_answer query parameter in the redirect" do
            post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1, changing_existing_answer: true), params: { question: }
            expect(response).to redirect_to review_file_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1, changing_existing_answer: true)
          end
        end
      end

      context "when the question was skipped" do
        let(:question) { { file: nil } }

        it "redirects to the next step in the form" do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: }
          expect(response).to redirect_to form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2)
        end
      end

      context "when there were validation errors" do
        let(:tempfile) { Tempfile.new(%w[temp-file .gif]) }
        let(:content_type) { "image/gif" }
        let(:question) { { file: Rack::Test::UploadedFile.new(tempfile.path, content_type) } }

        before do
          post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: }
        end

        after do
          tempfile.unlink
        end

        it "adds validation_errors logging attribute" do
          expect(log_lines[0]["validation_errors"]).to eq(["file: disallowed_type", "file: empty"])
        end

        it "adds answer_metadata logging attribute" do
          expect(log_lines[0]["answer_metadata"]).to eq({
            "file_size_in_bytes" => tempfile.size,
            "file_type" => "image/gif",
          })
        end
      end
    end

    context "when the page is a an exit question" do
      let(:first_step_in_form) do
        build :v2_question_page_step, :with_selections_settings,
              id: 1,
              next_step_id: 2,
              routing_conditions: [DataStruct.new(id: 1, routing_page_id: 1, check_page_id: 1, goto_page_id: nil, answer_value: "Option 1", validation_errors: [], exit_page_markdown: "Exit page markdown", exit_page_heading: "exit page heading")],
              is_optional: false
      end

      it "redirects to the exit page when exit page answer given" do
        post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { selection: "Option 1" }, changing_existing_answer: false })
        expect(response).to redirect_to exit_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
      end

      it "redirects to the next step in the form when any other answer given" do
        post save_form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { selection: "Option 2" }, changing_existing_answer: false })
        expect(response).to redirect_to form_page_path(mode:, form_id: 2, form_slug: form_data.form_slug, page_slug: 2)
      end
    end
  end

  def log_lines
    output.string.split("\n").map { |line| JSON.parse(line) }
  end
end
# rubocop:enable RSpec/AnyInstance
