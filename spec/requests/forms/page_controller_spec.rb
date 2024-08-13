require "rails_helper"

# rubocop:disable RSpec/AnyInstance
RSpec.describe Forms::PageController, type: :request do
  let(:timestamp_of_request) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }

  let(:form_data) do
    build(:form, :with_support,
          id: 2,
          live_at:,
          start_page: 1,
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          what_happens_next_markdown: "Good things come to those that wait",
          declaration_text: "agree to the declaration",
          pages: pages_data)
  end
  let(:live_at) { "2022-08-18 09:16:50 +0100" }

  let(:first_page_in_form) do
    build :page, :with_text_settings,
          id: 1,
          next_page: 2,
          is_optional: false
  end

  let(:second_page_in_form) do
    build :page, :with_text_settings,
          id: 2,
          is_optional:
  end

  let(:page_with_routing) do
    build :page, :with_selections_settings,
          id: 1,
          next_page: 2,
          routing_conditions: [DataStruct.new(id: 1, routing_page_id: 1, check_page_id: 1, goto_page_id: 3, answer_value: "Option 1", validation_errors:)],
          is_optional: false
  end

  let(:pages_data) { [first_page_in_form, second_page_in_form] }

  let(:is_optional) { false }

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:api_url_suffix) { "/live" }

  let(:output) { StringIO.new }
  let(:logger) { ActiveSupport::Logger.new(output) }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2#{api_url_suffix}", req_headers, form_data.to_json, 200
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
            pages: [
              build(:page, :with_text_settings,
                    id: page_id,
                    position: 1,
                    is_optional: false),
            ])
    end

    before do
      # Intercept the request logs so we can do assertions on them
      allow(Lograge).to receive(:logger).and_return(logger)

      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v1/forms/200#{api_url_suffix}", req_headers, form_data.to_json, 200
      end

      get form_page_path("form", 200, form_data.form_slug, page_id)
    end

    it "adds the page ID to the instrumentation payload" do
      expect(log_lines[0]["page_id"]).to eq(page_id.to_s)
    end

    it "adds the question_number to the instrumentation payload" do
      expect(log_lines[0]["question_number"]).to eq(1)
    end
  end

  describe "#show" do
    context "with preview mode on" do
      let(:api_url_suffix) { "/draft" }

      it "Returns a 200" do
        get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to first page if second request before first complete" do
        get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 2)
        expect(response).to redirect_to(form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1))
      end

      it "Displays the question text on the page" do
        get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.body).to include(form_data.pages.first.question_text)
      end

      it "Displays the privacy policy link on the page" do
        get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.body).to include("Privacy")
      end

      it "Displays the accessibility statement link on the page" do
        get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.body).to include("Accessibility statement")
      end

      it "Displays the Cookies link on the page" do
        get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.body).to include("Cookies")
      end

      context "with a page that has a previous page" do
        it "Displays a link to the previous page" do
          allow_any_instance_of(Flow::Context).to receive(:can_visit?).and_return(true)
          allow_any_instance_of(Flow::Context).to receive(:previous_step).and_return(OpenStruct.new(page_id: 1))
          get form_page_path("preview-draft", 2, form_data.form_slug, 2)
          expect(response.body).to include(form_page_path(2, form_data.form_slug, 1))
        end
      end

      context "with a change answers page" do
        it "Displays a back link to the check your answers page" do
          get form_change_answer_path("preview-draft", 2, form_data.form_slug, 1)
          expect(response.body).to include(check_your_answers_path("preview-draft", 2, form_data.form_slug))
        end

        it "Passes the changing answers parameter in its submit request" do
          get form_change_answer_path("preview-draft", 2, form_data.form_slug, 1)
          expect(response.body).to include(save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1, changing_existing_answer: true))
        end
      end

      it "Returns the correct X-Robots-Tag header" do
        get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end

      context "with no questions answered" do
        it "redirects if a later page is requested" do
          get check_your_answers_path("preview-draft", 2, form_data.form_slug)
          expect(response).to have_http_status(:found)
          expect(response.location).to eq(form_page_url(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1))
        end
      end
    end

    context "with preview mode off" do
      [
        "/form/2/1/check_your_answers_trailing",
        "/form/2/1/leading_check_your_answers",
        "/form/2/1/1/check_your_answers",
        "/form/2/1/1/ChEck_YouR_aNswers",
        "/form/2/1/1/0",
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

      it "Returns a 200" do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to first page if second request before first complete" do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 2)
        expect(response).to redirect_to(form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1))
      end

      it "Displays the question text on the page" do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.body).to include(form_data.pages.first.question_text)
      end

      it "Displays the privacy policy link on the page" do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.body).to include("Privacy")
      end

      it "Displays the accessibility statement link on the page" do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.body).to include("Accessibility statement")
      end

      it "Displays the Cookies link on the page" do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.body).to include("Cookies")
      end

      context "with a page that has a previous page" do
        it "Displays a link to the previous page" do
          allow_any_instance_of(Flow::Context).to receive(:can_visit?)
                                              .and_return(true)
          allow_any_instance_of(Flow::Context).to receive(:previous_step).and_return(OpenStruct.new(page_id: 1))
          get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 2)
          expect(response.body).to include(form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1))
        end
      end

      context "with a change answers page" do
        it "Displays a back link to the check your answers page" do
          get form_change_answer_path("form", 2, form_data.form_slug, 1)
          expect(response.body).to include(check_your_answers_path("form", 2, form_data.form_slug))
        end

        it "Passes the changing answers parameter in its submit request" do
          get form_change_answer_path("form", 2, form_data.form_slug, 1)
          expect(response.body).to include(save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1, changing_existing_answer: true))
        end
      end

      it "Returns the correct X-Robots-Tag header" do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end

      context "with no questions answered" do
        it "redirects if a later page is requested" do
          get check_your_answers_path("form", 2, form_data.form_slug)
          expect(response).to have_http_status(:found)
          expect(response.location).to eq(form_page_url(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1))
        end
      end

      context "and a form has a live_at value in the future" do
        let(:live_at) { "2023-01-01 09:00:00 +0100" }

        it "returns 404" do
          travel_to timestamp_of_request do
            get form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
          end

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when viewing a live form with no routing_conditions" do
      let(:first_page_in_form) do
        page_without_routing_condition = build(:page, :with_text_settings,
                                               id: 1,
                                               next_page: 2,
                                               is_optional: false)

        Page.new(page_without_routing_condition.attributes.except(:routing_conditions))
      end

      it "Returns a 200" do
        get form_page_path(mode: "preview-live", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when page has routing conditions" do
      let(:first_page_in_form) do
        page_with_routing
      end

      let(:validation_errors) { [] }

      let(:second_page_in_form) do
        build :page, :with_text_settings,
              id: 2,
              next_page: 3,
              is_optional:
      end

      let(:third_page_in_form) do
        build :page, :with_text_settings,
              id: 3,
              is_optional:
      end

      let(:pages_data) { [third_page_in_form, first_page_in_form, second_page_in_form] }

      let(:api_url_suffix) { "/draft" }

      context "when the routing has a cannot_have_goto_page_before_routing_page error" do
        let(:pages_data) { [first_page_in_form, second_page_in_form, third_page_in_form] }
        let(:validation_errors) { [{ name: "cannot_have_goto_page_before_routing_page" }] }

        it "returns a 422 response" do
          get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "shows the error page" do
          get form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1)
          link_url = "#{Settings.forms_admin.base_url}/forms/2/pages/1/conditions/1"
          question_number = first_page_in_form.position
          expect(response.body).to include(I18n.t("goto_page_before_routing_page.body_html", link_url:, question_number:))
        end
      end
    end
  end

  describe "#save" do
    before do
      allow_any_instance_of(Flow::Context).to receive(:clear_submission_details)
    end

    context "with preview mode on" do
      let(:api_url_suffix) { "/draft" }

      it "Redirects to the next page" do
        post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 2))
      end

      context "when changing an existing answer" do
        it "Redirects to the check your answers page" do
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
          expect(response).to redirect_to(check_your_answers_path("preview-draft", 2, form_data.form_slug))
        end

        it "does not log the change_answer_page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
        end
      end

      context "with the first page" do
        it "Logs the first_page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" } }
        end

        it "clears the submission reference from the session" do
          expect_any_instance_of(Flow::Context).to receive(:clear_submission_details).once
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" } }
        end
      end

      context "with a subsequent page" do
        it "Logs the page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
        end

        it "does not clear the submission reference from the session" do
          expect_any_instance_of(Flow::Context).not_to receive(:clear_submission_details)
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
        end
      end

      context "with the final page" do
        it "Redirects to the check your answers page" do
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
          expect(response).to redirect_to(check_your_answers_path("preview-draft", 2, form_data.form_slug))
        end
      end

      context "and a form has a live_at value in the future" do
        let(:live_at) { "2023-01-01 09:00:00 +0100" }

        it "does not return 404" do
          travel_to timestamp_of_request do
            post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
          end
          expect(response).not_to have_http_status(:not_found)
        end
      end

      context "when the form is invalid" do
        before do
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "" }, changing_existing_answer: false }
        end

        it "renders the show page template" do
          expect(response).to render_template("forms/page/show")
        end

        it "returns 422" do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "with preview mode off" do
      it "Redirects to the next page" do
        post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 2))
      end

      context "when changing an existing answer" do
        it "Redirects to the check your answers page" do
          post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
          expect(response).to redirect_to(check_your_answers_path("form", 2, form_data.form_slug))
        end

        it "Logs the change_answer_page_save event" do
          expect(EventLogger).to receive(:log_page_event).with("change_answer_page_save", first_page_in_form.question_text, nil)
          post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
        end
      end

      context "with the first page" do
        it "Logs the first_page_save event" do
          expect(EventLogger).to receive(:log_page_event).with("first_page_save", first_page_in_form.question_text, nil)
          post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "answer text" } }
        end
      end

      context "with a subsequent page" do
        it "Logs the page_save event" do
          expect(EventLogger).to receive(:log_page_event).with("page_save", second_page_in_form.question_text, nil)
          post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
        end
      end

      context "with the final page" do
        it "Redirects to the check your answers page" do
          post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
          expect(response).to redirect_to(check_your_answers_path("form", 2, form_data.form_slug))
        end
      end

      context "with an subsequent optional page" do
        let(:is_optional) { true }

        context "when an optional question is completed" do
          it "Logs the optional_save event with skipped_question as true" do
            expect(EventLogger).to receive(:log_page_event).with("optional_save", second_page_in_form.question_text, true)
            post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "" } }
          end
        end

        context "when an optional question is skipped" do
          it "Logs the optional_save event with skipped_question as false" do
            expect(EventLogger).to receive(:log_page_event).with("optional_save", second_page_in_form.question_text, false)
            post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 2), params: { question: { text: "answer text" } }
          end
        end
      end

      context "when the form is invalid" do
        before do
          post save_form_page_path(mode: "form", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { text: "" }, changing_existing_answer: false }
        end

        it "renders the show page template" do
          expect(response).to render_template("forms/page/show")
        end

        it "returns 422" do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when page has routing conditions" do
      let(:first_page_in_form) do
        page_with_routing
      end

      let(:validation_errors) { [] }

      let(:second_page_in_form) do
        build :page, :with_text_settings,
              id: 2,
              next_page: 3,
              is_optional:
      end

      let(:third_page_in_form) do
        build :page, :with_text_settings,
              id: 3,
              is_optional:
      end

      let(:pages_data) { [first_page_in_form, second_page_in_form, third_page_in_form] }

      let(:api_url_suffix) { "/draft" }

      it "redirects to the goto page if answer value matches condition" do
        post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { selection: "Option 1" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 3))
      end

      context "when the answer_value does not match the condition" do
        it "redirects to the next page in the journey" do
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { selection: "Option 2" }, changing_existing_answer: false }
          expect(response).to redirect_to(form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 2))
        end
      end

      context "when the routing has a cannot_have_goto_page_before_routing_page error" do
        let(:pages_data) { [first_page_in_form, second_page_in_form, third_page_in_form] }
        let(:validation_errors) { [{ name: "cannot_have_goto_page_before_routing_page" }] }

        it "returns a 422 response" do
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { selection: "Option 2" }, changing_existing_answer: false }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "shows the error page" do
          post save_form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug, page_slug: 1), params: { question: { selection: "Option 2" }, changing_existing_answer: false }
          link_url = "#{Settings.forms_admin.base_url}/forms/2/pages/1/conditions/1"
          question_number = first_page_in_form.position
          expect(response.body).to include(I18n.t("goto_page_before_routing_page.body_html", link_url:, question_number:))
        end
      end

      # TODO: Need to add test to check how changing an existing routing answer value would work. Better off as a feature spec which we dont have.
    end
  end

  def log_lines
    output.string.split("\n").map { |line| JSON.parse(line) }
  end
end
# rubocop:enable RSpec/AnyInstance
