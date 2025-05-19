require "rails_helper"

feature "Fill in and submit a form with a CSV submission", type: :feature do
  let(:steps) do
    [
      build(:v2_question_page_step, :with_selections_settings, id: 1, question_text: "A routing question", routing_conditions: [DataStruct.new(routing_page_id: 1, check_page_id: 1, answer_value: "Option 1", goto_page_id: nil, skip_to_end: true, validation_errors: [])], next_step_id: 2),
      build(:v2_question_page_step, :with_selections_settings, only_one_option: false, id: 2, question_text: "Skipped question", next_step_id: 3),
    ]
  end
  let(:form) { build :v2_form_document, :live?, id: 1, name: "Fill in this form", steps:, start_page: steps.first.id, submission_type: "email_with_csv" }
  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/1/live", req_headers, form.to_json, 200
    end

    allow(ReferenceNumberService).to receive(:generate).and_return(reference)

    travel_to Time.parse("2029-01-24T05:05:50+00:00")
  end

  after do
    travel_back
  end

  scenario "As a form filler" do
    when_i_visit_the_form_start_page
    then_i_should_see_the_first_question

    when_i_fill_in_the_question
    and_i_click_on_continue

    then_i_should_see_the_check_your_answers_page
    when_i_opt_out_of_email_confirmation
    and_i_submit_my_form

    then_my_form_should_be_submitted
    and_i_should_receive_a_reference_number
    and_an_email_submission_should_have_been_sent
  end

  def when_i_visit_the_form_start_page
    visit form_path(mode: "form", form_id: 1, form_slug: "fill-in-this-form")
    expect_page_to_have_no_axe_errors(page)
  end

  def then_i_should_see_the_first_question
    expect(page.find("h1")).to have_text "A routing question"
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
    click_on "Submit"
  end

  def and_an_email_submission_should_have_been_sent
    expect(SendSubmissionJob).to have_been_enqueued.with(an_instance_of(Submission) do |submission|
      expect(submission.form_id).to eq(form.id)
      expect(submission.reference).to eq(reference)
      expect(submission.answers).to eq({ "1" => { "selection" => "Option 1" } })
      expect(submission.created_at).to eq(Time.zone.parse("2029-01-24T05:05:50+00:00"))
      expect(submission.form_document["name"]).to eq("Fill in this form")
      expect(submission.form_document["submission_type"]).to eq("email_with_csv")
      expect(submission.form_document["submission_email"]).to eq(form.submission_email)
    end)
  end

  def then_my_form_should_be_submitted
    expect(page.find("h1")).to have_text "Your form has been submitted"
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_should_receive_a_reference_number
    expect(page).to have_text reference
  end
end
