require "rails_helper"

feature "Fill in and submit a form with a file upload question", type: :feature do
  include ActiveJob::TestHelper

  let(:steps) { [(build :v2_question_page_step, answer_type: "file", id: 1, routing_conditions: [], question_text:)] }
  let(:form) { build :v2_form_document, :live?, id: 1, name: "Fill in this form", steps:, start_page: 1 }
  let(:question_text) { Faker::Lorem.question }
  let(:answer_text) { "Answer 1" }
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

  let(:test_file) { "tmp/a-file.txt" }

  after do
    File.delete(test_file) if File.exist?(test_file)
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/1/live", req_headers, form.to_json, 200
    end

    allow(ReferenceNumberService).to receive(:generate).and_return(reference)

    mock_s3_client = Aws::S3::Client.new(stub_responses: true)
    allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
    allow(mock_s3_client).to receive(:put_object)
    allow(mock_s3_client).to receive(:get_object_tagging).and_return({ tag_set: [{ key: "GuardDutyMalwareScanStatus", value: scan_status }] })

    File.write(test_file, "some content")
  end

  context "when the file is successfully uploaded" do
    let(:scan_status) { "NO_THREATS_FOUND" }

    scenario "As a form filler" do
      when_i_visit_the_form_start_page
      then_i_should_see_the_first_question
      then_i_see_the_file_upload_component
      when_i_upload_a_file
      and_i_click_on_continue
      then_i_see_the_review_file_page
      and_i_click_on_continue
      then_i_should_see_the_check_your_answers_page

      when_i_opt_out_of_email_confirmation
      and_i_submit_my_form
      then_my_form_should_be_submitted
      and_i_should_receive_a_reference_number
      and_an_email_submission_should_have_been_sent
    end
  end

  context "when the file fails the virus scan" do
    let(:scan_status) { "THREATS_FOUND" }

    scenario "As a form filler" do
      when_i_visit_the_form_start_page
      then_i_should_see_the_first_question
      then_i_see_the_file_upload_component
      when_i_upload_a_file
      and_i_click_on_continue
      then_i_see_an_error_message_that_the_file_contains_a_virus
    end
  end

  def when_i_visit_the_form_start_page
    visit form_path(mode: "form", form_id: 1, form_slug: "fill-in-this-form")
    expect_page_to_have_no_axe_errors(page)
  end

  def then_i_should_see_the_first_question
    expect(page.find("h1")).to have_text question_text
  end

  def then_i_see_the_file_upload_component
    expect(page).to have_css("input[type=file]")
  end

  def when_i_upload_a_file
    attach_file question_text, test_file
  end

  def and_i_click_on_continue
    click_button "Continue"
  end

  def then_i_see_the_review_file_page
    expect(page.find("h1")).to have_text question_text
    expect(page).to have_text "Check your uploaded file"
    expect(page).to have_text File.basename(File.path(test_file))
  end

  def then_i_should_see_the_check_your_answers_page
    expect(page.find("h1")).to have_text "Check your answers before submitting your form"
    expect(page).to have_text question_text
    expect(page).to have_text File.basename(test_file)
    expect_page_to_have_no_axe_errors(page)
  end

  def when_i_opt_out_of_email_confirmation
    choose "No"
  end

  def and_i_submit_my_form
    click_on "Submit"
  end

  def then_my_form_should_be_submitted
    expect(page.find("h1")).to have_text "Your form has been submitted"
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_should_receive_a_reference_number
    expect(page).to have_text reference
  end

  def and_an_email_submission_should_have_been_sent
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.first).to be_present

    delivered_email = ActionMailer::Base.deliveries.first

    expect(delivered_email.html_part.body.raw_source).to match(/a-file_#{reference}.txt/)
  end

  def then_i_see_an_error_message_that_the_file_contains_a_virus
    expect(page.find(".govuk-error-summary")).to have_text "The selected file contains a virus"
    expect(page).to have_css("input[type=file]")
  end
end
