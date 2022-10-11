require "rails_helper"

RSpec.describe "Page Controller", type: :request do
  let(:timestamp_of_request) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }
  let(:form_data) do
    {
      id: 2,
      name: "Form 1",
      form_slug: "form-1",
      submission_email: "submission@email.com",
      start_page: 1,
      live_at: "2022-08-18 09:16:50 +0100",
      privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
      what_happens_next_text: "Good things come to those that wait",
      support_email: "help@example.gov.uk",
      support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
      support_url: "https://example.gov.uk/contact",
      support_url_text: "Contact us",
    }.to_json
  end

  let(:pages_data) do
    [
      {
        id: 1,
        question_text: "Question one",
        answer_type: "single_line",
        hint_text: "",
        next_page: 2,
        question_short_name: nil,
        is_optional: nil,
      },
      {
        id: 2,
        question_text: "Question two",
        hint_text: "Q2 hint text",
        answer_type: "single_line",
        question_short_name: nil,
        is_optional: nil,
      },
    ].to_json
  end

  let(:req_headers) do
    {
      "X-API-Token" => ENV["API_KEY"],
      "Accept" => "application/json",
    }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2", req_headers, form_data, 200
      mock.get "/api/v1/forms/2/pages", req_headers, pages_data, 200
    end
  end

  describe "#show" do
    context "with preview mode on" do
      it "Returns a 200" do
        get form_page_path("preview-form", 2, "form-1", 1)
        expect(response.status).to eq(200)
      end

      it "redirects to first page if second request before first complete" do
        get form_page_path("preview-form", 2, "form-1", 2)
        expect(response).to redirect_to(form_page_path(2, "form-1", 1))
      end

      it "Displays the question text on the page" do
        get form_page_path("preview-form", 2, "form-1", 1)
        expect(response.body).to include("Question one")
      end

      it "Displays the privacy policy link on the page" do
        get form_page_path("preview-form", 2, "form-1", 1)
        expect(response.body).to include("Privacy")
      end

      it "Displays the accessibility statement link on the page" do
        get form_page_path("preview-form", 2, "form-1", 1)
        expect(response.body).to include("Accessibility statement")
      end

      it "Displays the Cookies link on the page" do
        get form_page_path("preview-form", 2, "form-1", 1)
        expect(response.body).to include("Cookies")
      end

      context "with a page that has a previous page" do
        it "Displays a link to the previous page" do
          allow_any_instance_of(Context).to receive(:can_visit?)
                                              .and_return(true)
          allow_any_instance_of(Context).to receive(:previous_step).and_return(1)
          get form_page_path("preview-form", 2, "form-1", 2)
          expect(response.body).to include(form_page_path(2, "form-1", 1))
        end
      end

      context "with a change answers page" do
        it "Displays a back link to the check your answers page" do
          get form_change_answer_path("preview-form", 2, "form-1", 1)
          expect(response.body).to include(check_your_answers_path("preview-form", 2, "form-1"))
        end

        it "Passes the changing answers parameter in its submit request" do
          get form_change_answer_path("preview-form", 2, "form-1", 1)
          expect(response.body).to include(save_form_page_path("preview-form", 2, "form-1", 1, changing_existing_answer: true))
        end
      end

      it "Returns the correct X-Robots-Tag header" do
        get form_page_path("preview-form", 2, "form-1", 1)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end

      context "with no questions answered" do
        it "redirects if a later page is requested" do
          get check_your_answers_path("preview-form", 2, "form-1")
          expect(response.status).to eq(302)
          expect(response.location).to eq(form_page_url("preview-form", 2, "form-1", 1))
        end
      end
    end

    context "with preview mode off" do
      it "Returns a 200" do
        get form_page_path("form", 2, "form-1", 1)
        expect(response.status).to eq(200)
      end

      it "redirects to first page if second request before first complete" do
        get form_page_path("form", 2, "form-1", 2)
        expect(response).to redirect_to(form_page_path(2, "form-1", 1))
      end

      it "Displays the question text on the page" do
        get form_page_path("form", 2, "form-1", 1)
        expect(response.body).to include("Question one")
      end

      it "Displays the privacy policy link on the page" do
        get form_page_path("form", 2, "form-1", 1)
        expect(response.body).to include("Privacy")
      end

      it "Displays the accessibility statement link on the page" do
        get form_page_path("form", 2, "form-1", 1)
        expect(response.body).to include("Accessibility statement")
      end

      it "Displays the Cookies link on the page" do
        get form_page_path("form", 2, "form-1", 1)
        expect(response.body).to include("Cookies")
      end

      context "with a page that has a previous page" do
        it "Displays a link to the previous page" do
          allow_any_instance_of(Context).to receive(:can_visit?)
                                              .and_return(true)
          allow_any_instance_of(Context).to receive(:previous_step).and_return(1)
          get form_page_path("form", 2, "form-1", 2)
          expect(response.body).to include(form_page_path(2, "form-1", 1))
        end
      end

      context "with a change answers page" do
        it "Displays a back link to the check your answers page" do
          get form_change_answer_path("form", 2, "form-1", 1)
          expect(response.body).to include(check_your_answers_path("form", 2, "form-1"))
        end

        it "Passes the changing answers parameter in its submit request" do
          get form_change_answer_path("form", 2, "form-1", 1)
          expect(response.body).to include(save_form_page_path("form", 2, "form-1", 1, changing_existing_answer: true))
        end
      end

      it "Returns the correct X-Robots-Tag header" do
        get form_page_path("form", 2, "form-1", 1)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end

      context "with no questions answered" do
        it "redirects if a later page is requested" do
          get check_your_answers_path("form", 2, "form-1")
          expect(response.status).to eq(302)
          expect(response.location).to eq(form_page_url("form", 2, "form-1", 1))
        end
      end

      context "and a form has a live_at value in the future" do
        let(:form_data) do
          {
            id: 2,
            name: "Form name",
            form_slug: "form-name",
            submission_email: "submission@email.com",
            live_at: "2023-01-01 09:00:00 +0100",
            start_page: "1",
            privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          }.to_json
        end

        it "returns 404" do
          travel_to timestamp_of_request do
            get form_page_path("form", 2, "form-1", 1)
          end

          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "#save" do
    context "with preview mode on" do
      it "Redirects to the next page" do
        post save_form_page_path("preview-form", 2, "form-1", 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path("preview-form", 2, "form-1", 2))
      end

      context "when changing an existing answer" do
        it "Redirects to the check your answers page" do
          post save_form_page_path("preview-form", 2, "form-1", 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
          expect(response).to redirect_to(check_your_answers_path("preview-form", 2, "form-1"))
        end

        it "does not log the change_answer_page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path("preview-form", 2, "form-1", 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
        end
      end

      context "with the first page" do
        it "Logs the first_page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path("preview-form", 2, "form-1", 1), params: { question: { text: "answer text" } }
        end
      end

      context "with a subsequent page" do
        it "Logs the page_save event" do
          expect(EventLogger).not_to receive(:log)
          post save_form_page_path("preview-form", 2, "form-1", 2), params: { question: { text: "answer text" } }
        end
      end

      context "with the final page" do
        it "Redirects to the check your answers page" do
          post save_form_page_path("preview-form", 2, "form-1", 2), params: { question: { text: "answer text" } }
          expect(response).to redirect_to(check_your_answers_path("preview-form", 2, "form-1"))
        end
      end
    end

    context "and a form has a live_at value in the future" do
      let(:form_data) do
        {
          id: 2,
          name: "Form name",
          form_slug: "form-name",
          submission_email: "submission@email.com",
          live_at: "2023-01-01 09:00:00 +0100",
          start_page: "1",
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          what_happens_next_text: "Good things come to those that wait",
          support_email: "help@example.gov.uk",
          support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
          support_url: "https://example.gov.uk/contact",
          support_url_text: "Contact us",
        }.to_json
      end

      it "does not return 404" do
        travel_to timestamp_of_request do
          post save_form_page_path("preview-form", 2, "form-1", 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        end
        expect(response.status).not_to eq(404)
      end
    end

    context "with preview mode off" do
      it "Redirects to the next page" do
        post save_form_page_path("form", 2, "form-1", 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        expect(response).to redirect_to(form_page_path("form", 2, "form-1", 2))
      end

      context "when changing an existing answer" do
        it "Redirects to the check your answers page" do
          post save_form_page_path("form", 2, "form-1", 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
          expect(response).to redirect_to(check_your_answers_path("form", 2, "form-1"))
        end

        it "Logs the change_answer_page_save event" do
          expect(EventLogger).to receive(:log).with("change_answer_page_save",
                                                    { form: "Form 1",
                                                      method: "POST",
                                                      question_text: "Question one",
                                                      url: "http://www.example.com/form/2/form-1/1?changing_existing_answer=true&question%5Btext%5D=answer+text" })
          post save_form_page_path("form", 2, "form-1", 1, params: { question: { text: "answer text" }, changing_existing_answer: true })
        end
      end

      context "with the first page" do
        it "Logs the first_page_save event" do
          expect(EventLogger).to receive(:log).with("first_page_save",
                                                    { form: "Form 1",
                                                      method: "POST",
                                                      question_text: "Question one",
                                                      url: "http://www.example.com/form/2/form-1/1" })
          post save_form_page_path("form", 2, "form-1", 1), params: { question: { text: "answer text" } }
        end
      end

      context "with a subsequent page" do
        it "Logs the page_save event" do
          expect(EventLogger).to receive(:log).with("page_save",
                                                    { form: "Form 1",
                                                      method: "POST",
                                                      question_text: "Question two",
                                                      url: "http://www.example.com/form/2/form-1/2" })
          post save_form_page_path("form", 2, "form-1", 2), params: { question: { text: "answer text" } }
        end
      end

      context "with the final page" do
        it "Redirects to the check your answers page" do
          post save_form_page_path("form", 2, "form-1", 2), params: { question: { text: "answer text" } }
          expect(response).to redirect_to(check_your_answers_path("form", 2, "form-1"))
        end
      end
    end
  end
end
