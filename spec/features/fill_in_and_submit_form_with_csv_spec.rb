require "rails_helper"

feature "Fill in and submit a form with a CSV submission", type: :feature do
  let(:steps) do
    [
      build(:v2_question_page_step, :with_text_settings, id: 1, question_text:, next_step_id: 2),
      build(:v2_question_page_step, :with_text_settings, id: 2, is_optional: true, question_text: "An optional question?", next_step_id: 3),
      build(:v2_question_page_step, :with_selections_settings, id: 3, question_text: "A routing question?", routing_conditions: [DataStruct.new(routing_page_id: 3, check_page_id: 3, answer_value: "Option 1", goto_page_id: nil, skip_to_end: true, validation_errors: [])]),
      build(:v2_question_page_step, :with_text_settings, id: 4, question_text: "a question skipped through routing"),

    ]
  end
  let(:form) { build :v2_form_document, :live?, id: 1, name: "Fill in this form", steps:, start_page: steps.first.id, submission_type: "email_with_csv" }
  let(:question_text) { Faker::Lorem.question }
  let(:answer_text) { "Answer text" }

  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

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
      mock.get "/api/v2/forms/1/live", req_headers, form.to_json, 200
    end

    allow(ReferenceNumberService).to receive(:generate).and_return(reference)
  end

  scenario "As a form filler" do
    when_i_visit_the_form_start_page
    then_i_should_see_the_first_question

    when_i_fill_in_the_question
    and_i_click_on_continue

    then_i_should_see_the_optional_question
    and_i_click_on_continue

    then_i_should_see_the_routing_question
    and_i_fill_out_the_routing_question
    and_i_click_on_continue

    then_i_should_see_the_check_your_answers_page
    when_i_opt_out_of_email_confirmation

    # We freeze time so we can test the value of the submission timestamp
    freeze_time do
      and_i_submit_my_form
      then_an_email_submission_should_have_been_sent
    end

    then_my_form_should_be_submitted
    and_i_should_receive_a_reference_number
  end

  def when_i_visit_the_form_start_page
    visit form_path(mode: "form", form_id: 1, form_slug: "fill-in-this-form")
    expect_page_to_have_no_axe_errors(page)
  end

  def then_i_should_see_the_first_question
    expect(page.find("h1")).to have_text question_text
  end

  def when_i_fill_in_the_question
    fill_in question_text, with: answer_text
  end

  def and_i_click_on_continue
    click_button "Continue"
  end

  def then_i_should_see_the_optional_question
    expect(page.find("h1")).to have_text "An optional question?"
  end

  def then_i_should_see_the_routing_question
    expect(page.find("h1")).to have_text "A routing question?"
  end

  def and_i_fill_out_the_routing_question
    choose "Option 1"
  end

  def then_i_should_see_the_check_your_answers_page
    expect(page.find("h1")).to have_text "Check your answers before submitting your form"
    expect(page).to have_text question_text
    expect(page).to have_text answer_text
    expect_page_to_have_no_axe_errors(page)
  end

  def when_i_opt_out_of_email_confirmation
    choose "No"
  end

  def and_i_submit_my_form
    click_on "Submit"
  end

  def then_an_email_submission_should_have_been_sent
    delivered_email = ActionMailer::Base.deliveries.first

    expected_content = [
      ["Reference", "Submitted at", question_text, "An optional question?", "A routing question?", "a question skipped through routing"],
      [reference, formatted_timestamp, answer_text, "", "Option 1", ""],
    ]

    expect(parse_email_csv(delivered_email)).to match_array(expected_content)
  end

  def then_my_form_should_be_submitted
    expect(page.find("h1")).to have_text "Your form has been submitted"
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
