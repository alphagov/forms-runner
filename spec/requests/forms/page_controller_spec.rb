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
          what_happens_next_text: "Good things come to those that wait",
          declaration_text: "agree to the declaration",
          pages: pages_data)
  end
  let(:live_at) { "2022-08-18 09:16:50 +0100" }

  let(:page_1) do
    build :page, :with_text_settings,
          id: 1,
          next_page: 2,
          is_optional: false
  end

  let(:page_2) do
    build :page, :with_text_settings,
          id: 2,
          is_optional:
  end

  let(:page_3) do
    build :page, :with_text_settings,
          id: 3,
          is_optional:
  end

  let(:pages_data) { [page_1, page_2] }

  let(:is_optional) { false }

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:api_url_suffix) { "/live" }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2#{api_url_suffix}", req_headers, form_data.to_json, 200
    end
  end

  describe "#show" do
    context "with preview mode on" do
      let(:api_url_suffix) { "/draft" }

      it "Returns a 200" do
        get form_page_path("preview-draft", 2, form_data.form_slug, 1)
        expect(response.status).to eq(200)
      end

      it "redirects to first page if second request before first complete" do
        get form_page_path("preview-draft", 2, form_data.form_slug, 2)
        expect(response).to redirect_to(form_page_path(2, form_data.form_slug, 1))
      end

      it "Displays the question text on the page" do
        get form_page_path("preview-draft", 2, form_data.form_slug, 1)
        expect(response.body).to include(form_data.pages.first.question_text)
      end

      it "Displays the privacy policy link on the page" do
        get form_page_path("preview-draft", 2, form_data.form_slug, 1)
        expect(response.body).to include("Privacy")
      end

      it "Displays the accessibility statement link on the page" do
        get form_page_path("preview-draft", 2, form_data.form_slug, 1)
        expect(response.body).to include("Accessibility statement")
      end

      it "Displays the Cookies link on the page" do
        get form_page_path("preview-draft", 2, form_data.form_slug, 1)
        expect(response.body).to include("Cookies")
      end

      context "with a page that has a previous page" do
        it "Displays a link to the previous page" do
          allow_any_instance_of(Context).to receive(:can_visit?)
                                              .and_return(true)
          allow_any_instance_of(Context).to receive(:previous_step).and_return(1)
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
          expect(response.body).to include(save_form_page_path("preview-draft", 2, form_data.form_slug, 1, changing_existing_answer: true))
        end
      end

      it "Returns the correct X-Robots-Tag header" do
        get form_page_path("preview-draft", 2, form_data.form_slug, 1)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end

      context "with no questions answered" do
        it "redirects if a later page is requested" do
          get check_your_answers_path("preview-draft", 2, form_data.form_slug)
          expect(response.status).to eq(302)
          expect(response.location).to eq(form_page_url("preview-draft", 2, form_data.form_slug, 1))
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
            expect(response.status).to eq(404)
          end

          it "does not send an expception to sentry" do
            expect(Sentry).not_to have_received(:capture_exception)
          end
        end
      end

      it "Returns a 200" do
        get form_page_path("form", 2, form_data.form_slug, 1)
        expect(response.status).to eq(200)
      end

      it "redirects to first page if second request before first complete" do
        get form_page_path("form", 2, form_data.form_slug, 2)
        expect(response).to redirect_to(form_page_path(2, form_data.form_slug, 1))
      end

      it "Displays the question text on the page" do
        get form_page_path("form", 2, form_data.form_slug, 1)
        expect(response.body).to include(form_data.pages.first.question_text)
      end

      it "Displays the privacy policy link on the page" do
        get form_page_path("form", 2, form_data.form_slug, 1)
        expect(response.body).to include("Privacy")
      end

      it "Displays the accessibility statement link on the page" do
        get form_page_path("form", 2, form_data.form_slug, 1)
        expect(response.body).to include("Accessibility statement")
      end

      it "Displays the Cookies link on the page" do
        get form_page_path("form", 2, form_data.form_slug, 1)
        expect(response.body).to include("Cookies")
      end

      context "with a page that has a previous page" do
        it "Displays a link to the previous page" do
          allow_any_instance_of(Context).to receive(:can_visit?)
                                              .and_return(true)
          allow_any_instance_of(Context).to receive(:previous_step).and_return(1)
          get form_page_path("form", 2, form_data.form_slug, 2)
          expect(response.body).to include(form_page_path(2, form_data.form_slug, 1))
        end
      end

      context "with a change answers page" do
        it "Displays a back link to the check your answers page" do
          get form_change_answer_path("form", 2, form_data.form_slug, 1)
          expect(response.body).to include(check_your_answers_path("form", 2, form_data.form_slug))
        end

        it "Passes the changing answers parameter in its submit request" do
          get form_change_answer_path("form", 2, form_data.form_slug, 1)
          expect(response.body).to include(save_form_page_path("form", 2, form_data.form_slug, 1, changing_existing_answer: true))
        end
      end

      it "Returns the correct X-Robots-Tag header" do
        get form_page_path("form", 2, form_data.form_slug, 1)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end

      context "with no questions answered" do
        it "redirects if a later page is requested" do
          get check_your_answers_path("form", 2, form_data.form_slug)
          expect(response.status).to eq(302)
          expect(response.location).to eq(form_page_url("form", 2, form_data.form_slug, 1))
        end
      end

      context "and a form has a live_at value in the future" do
        let(:live_at) { "2023-01-01 09:00:00 +0100" }

        it "returns 404" do
          travel_to timestamp_of_request do
            get form_page_path("form", 2, form_data.form_slug, 1)
          end

          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "#save" do
    context "with preview mode on" do
      let(:api_url_suffix) { "/draft" }

      it "Redirects to the next page" do
        post save_form_page_path("preview-draft", 2, form_data.form_slug, 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path("preview-draft", 2, form_data.form_slug, 2))
      end

      context "when changing an existing answer" do
        it "Redirects to the check your answers page" do
          post save_form_page_path("preview-draft", 2, form_data.form_slug, 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
          expect(response).to redirect_to(check_your_answers_path("preview-draft", 2, form_data.form_slug))
        end

        it "does not log the change_answer_page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path("preview-draft", 2, form_data.form_slug, 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
        end
      end

      context "with the first page" do
        it "Logs the first_page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path("preview-draft", 2, form_data.form_slug, 1), params: { question: { text: "answer text" } }
        end
      end

      context "with a subsequent page" do
        it "Logs the page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path("preview-draft", 2, form_data.form_slug, 2), params: { question: { text: "answer text" } }
        end
      end

      context "with the final page" do
        it "Redirects to the check your answers page" do
          post save_form_page_path("preview-draft", 2, form_data.form_slug, 2), params: { question: { text: "answer text" } }
          expect(response).to redirect_to(check_your_answers_path("preview-draft", 2, form_data.form_slug))
        end
      end

      context "and a form has a live_at value in the future" do
        let(:live_at) { "2023-01-01 09:00:00 +0100" }

        it "does not return 404" do
          travel_to timestamp_of_request do
            post save_form_page_path("preview-draft", 2, form_data.form_slug, 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
          end
          expect(response.status).not_to eq(404)
        end
      end
    end

    context "with preview mode off" do
      it "Redirects to the next page" do
        post save_form_page_path("form", 2, form_data.form_slug, 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path("form", 2, form_data.form_slug, 2))
      end

      context "when changing an existing answer" do
        it "Redirects to the check your answers page" do
          post save_form_page_path("form", 2, form_data.form_slug, 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
          expect(response).to redirect_to(check_your_answers_path("form", 2, form_data.form_slug))
        end

        it "Logs the change_answer_page_save event" do
          expect(EventLogger).to receive(:log).with("change_answer_page_save",
                                                    { form: form_data.name,
                                                      method: "POST",
                                                      question_number: 1,
                                                      question_text: form_data.pages.first.question_text,
                                                      url: "http://www.example.com/form/2/#{form_data.form_slug}/1?changing_existing_answer=true&question%5Btext%5D=answer+text" })
          post save_form_page_path("form", 2, form_data.form_slug, 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
        end
      end

      context "with the first page" do
        it "Logs the first_page_save event" do
          expect(EventLogger).to receive(:log).with("first_page_save",
                                                    { form: form_data.name,
                                                      method: "POST",
                                                      question_number: 1,
                                                      question_text: form_data.pages.first.question_text,
                                                      url: "http://www.example.com/form/2/#{form_data.form_slug}/1" })
          post save_form_page_path("form", 2, form_data.form_slug, 1), params: { question: { text: "answer text" } }
        end
      end

      context "with a subsequent page" do
        it "Logs the page_save event" do
          expect(EventLogger).to receive(:log).with("page_save",
                                                    { form: form_data.name,
                                                      method: "POST",
                                                      question_number: 2,
                                                      question_text: form_data.pages.second.question_text,
                                                      url: "http://www.example.com/form/2/#{form_data.form_slug}/2" })
          post save_form_page_path("form", 2, form_data.form_slug, 2), params: { question: { text: "answer text" } }
        end
      end

      context "with the final page" do
        it "Redirects to the check your answers page" do
          post save_form_page_path("form", 2, form_data.form_slug, 2), params: { question: { text: "answer text" } }
          expect(response).to redirect_to(check_your_answers_path("form", 2, form_data.form_slug))
        end
      end

      context "with an subsequent optional page" do
        let(:is_optional) { true }

        context "when an optional question is completed" do
          it "Logs the optional_save event with skipped_question as true" do
            expect(EventLogger).to receive(:log).with("optional_save",
                                                      { form: form_data.name,
                                                        method: "POST",
                                                        question_number: 2,
                                                        question_text: form_data.pages.second.question_text,
                                                        skipped_question: "false",
                                                        url: "http://www.example.com/form/2/#{form_data.form_slug}/2" })
            post save_form_page_path("form", 2, form_data.form_slug, 2), params: { question: { text: "answer text" } }
          end
        end

        context "when an optional question is skipped" do
          it "Logs the optional_save event with skipped_question as false" do
            expect(EventLogger).to receive(:log).with("optional_save",
                                                      { form: form_data.name,
                                                        method: "POST",
                                                        question_number: 2,
                                                        question_text: form_data.pages.second.question_text,
                                                        skipped_question: "true",
                                                        url: "http://www.example.com/form/2/#{form_data.form_slug}/2" })
            post save_form_page_path("form", 2, form_data.form_slug, 2), params: { question: { text: "" } }
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance
