require "rails_helper"

feature "Fill in and submit a form with a CSV submission", type: :feature do
  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

  let(:json) do
    <<~JSON
      {
        "form_id": "21",
        "name": "A form which breaks CSVs",
        "submission_email": "eaxmple@sub-domain.gov.uk",
        "privacy_policy_url": "https://www.gov.uk/help/privacy-notice",
        "form_slug": "a-form-which-breaks-csvs",
        "support_email": null,
        "support_phone": "0113 272727",
        "support_url": null,
        "support_url_text": null,
        "declaration_text": "By submitting this form you’re confirming that, to the best of your knowledge, the answers you’re providing are correct. ",
        "question_section_completed": true,
        "declaration_section_completed": true,
        "created_at": "2025-01-24T13:36:51.462Z",
        "updated_at": "2025-01-24T15:09:03.424Z",
        "creator_id": 1,
        "what_happens_next_markdown": "We’ll send you an email to let you know the outcome. You’ll usually get a response within 10 working days.",
        "payment_url": "https://www.gov.uk/payments/your-payment-link",
        "submission_type": "email_with_csv",
        "share_preview_completed": true,
        "s3_bucket_name": null,
        "s3_bucket_aws_account_id": null,
        "s3_bucket_region": null,
        "start_page": 88,
        "live_at": "2025-01-24T15:09:03.424Z",
        "steps": [
          {
            "id": 88,
            "position": 1,
            "next_step_id": 89,
            "type": "question_page",
            "data": {
              "question_text": "Which is it?",
              "hint_text": "",
              "answer_type": "selection",
              "is_optional": false,
              "answer_settings": {
                "only_one_option": "true",
                "selection_options": [
                  {
                    "name": "Option 1"
                  },
                  {
                    "name": "Option 2"
                  }
                ]
              },
              "page_heading": null,
              "guidance_markdown": null,
              "is_repeatable": false
            },
            "routing_conditions": [
              {
                "id": 101,
                "check_page_id": 88,
                "routing_page_id": 88,
                "goto_page_id": null,
                "answer_value": "Option 1",
                "created_at": "2025-01-24T14:29:14.443Z",
                "updated_at": "2025-01-24T14:29:14.443Z",
                "skip_to_end": true,
                "validation_errors": []
              }
            ]
          },
          {
            "id": 89,
            "position": 2,
            "next_step_id": 90,
            "type": "question_page",
            "data": {
              "question_text": "Nested selection question",
              "hint_text": "",
              "answer_type": "selection",
              "is_optional": false,
              "answer_settings": {
                "only_one_option": "false",
                "selection_options": [
                  {
                    "name": "Yes"
                  },
                  {
                    "name": "No"
                  }
                ]
              },
              "page_heading": null,
              "guidance_markdown": null,
              "is_repeatable": false
            },
            "routing_conditions": []
          },
          {
            "id": 90,
            "position": 3,
            "next_step_id": null,
            "type": "question_page",
            "data": {
              "question_text": "How many times?",
              "hint_text": "",
              "answer_type": "number",
              "is_optional": false,
              "answer_settings": null,
              "page_heading": null,
              "guidance_markdown": null,
              "is_repeatable": false
            },
            "routing_conditions": []
          }
        ]
      }
    JSON
  end

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:post_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Content-Type" => "application/json",
    }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/21/live", req_headers, json, 200
    end

    allow(ReferenceNumberService).to receive(:generate).and_return(reference)
  end

  scenario "As a form filler" do
    when_i_visit_the_form_start_page
    then_i_should_see_the_first_question

    when_i_fill_in_the_question
    and_i_click_on_continue

    then_i_should_see_the_check_your_answers_page
    when_i_opt_out_of_email_confirmation

    # # We freeze time so we can test the value of the submission timestamp
    freeze_time do
      and_i_submit_my_form
      then_an_email_submission_should_have_been_sent
    end

    then_my_form_should_be_submitted
    and_i_should_receive_a_reference_number
  end

  def when_i_visit_the_form_start_page
    visit form_path(mode: "form", form_id: 21, form_slug: "a-form-which-breaks-csvs")
    expect_page_to_have_no_axe_errors(page)
  end

  def then_i_should_see_the_first_question
    expect(page.find("h1")).to have_text "Which is it?"
  end

  def when_i_fill_in_the_question
    choose "Option 1"
  end

  def and_i_click_on_continue
    click_button "Continue"
  end

  def then_i_should_see_the_check_your_answers_page
    expect(page.find("h1")).to have_text "Check your answers before submitting your form"
    expect_page_to_have_no_axe_errors(page)
  end

  def when_i_opt_out_of_email_confirmation
    choose "No"
  end

  def and_i_submit_my_form
    click_on "Agree and submit"
  end

  def then_an_email_submission_should_have_been_sent
    expect(ActionMailer::Base.deliveries.first).to be_present

    delivered_email = ActionMailer::Base.deliveries.first

    expected_content = [
      ["Reference", "Submitted at", "Which is it?", "Nested selection question", "How many times?"],
      [reference, formatted_timestamp, "Option 1", "", ""],
    ]

    expect(parse_email_csv(delivered_email)).to match_array(expected_content)
  end

  def then_my_form_should_be_submitted
    expect(page.find("h1")).to have_text "You still need to pay"
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_should_receive_a_reference_number
    expect(page).to have_text reference
  end

  def parse_email_csv(email)
    CSV.parse(
      Base64.strict_decode64(
        email.govuk_notify_personalisation[:link_to_file][:file],
      ),
    )
  end

  def formatted_timestamp
    timezone = Rails.configuration.x.submission.time_zone || "UTC"
    Time.use_zone(timezone) { Time.zone.now.iso8601 }
  end
end
