require "rails_helper"

feature "Fill in and submit a form with a single repeatable question", type: :feature do
  let(:pages) { [(build :page, :with_repeatable, answer_type: "number")] }
  let(:form) { build :form, :live?, id: 42, name: "Form with repeating question", pages:, start_page: pages.first.id }

  let(:question_text) { pages[0].question_text }
  let(:first_answer_text) { "99" }
  let(:second_answer_text) { "7" }
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
      mock.get "/api/v1/forms/42", req_headers, form.to_json, 200
      mock.get "/api/v1/forms/42/live", req_headers, form.to_json(include: [:pages]), 200
    end

    allow(ReferenceNumberService).to receive(:generate).and_return(reference)
  end

  scenario "As a form filler" do
    when_i_visit_the_form_start_page
    then_i_should_see_the_first_question

    when_i_fill_in_the_question
    and_i_click_on_continue

    then_i_should_see_the_add_another_page

    when_i_choose_to_add_another
    and_i_click_on_continue

    then_i_should_see_the_first_question
    when_i_fill_in_the_question_with_my_second_answer
    and_i_click_on_continue

    then_i_should_see_the_add_another_page_with_my_second_answer

    when_i_choose_not_to_add_another
    and_i_click_on_continue

    then_i_should_see_the_check_your_answers_page
    when_i_opt_out_of_email_confirmation
    and_i_submit_my_form
    then_my_form_should_be_submitted
    and_i_should_receive_a_reference_number
  end

  def when_i_visit_the_form_start_page
    visit form_path(mode: "form", form_id: 42, form_slug: "form-with-repeating-question")
    expect_page_to_have_no_axe_errors(page)
  end

  def then_i_should_see_the_first_question
    expect(page.find("h1")).to have_text question_text
  end

  def when_i_fill_in_the_question
    fill_in question_text, with: first_answer_text
  end

  def and_i_click_on_continue
    click_button "Continue"
  end

  def then_i_should_see_the_add_another_page
    expect(page.find("h1")).to have_text "You have added one answer"
    expect(page).to have_text first_answer_text
    expect_page_to_have_no_axe_errors(page)
  end

  def when_i_choose_to_add_another
    choose "Yes"
  end

  def when_i_fill_in_the_question_with_my_second_answer
    fill_in question_text, with: second_answer_text
  end

  def then_i_should_see_the_add_another_page_with_my_second_answer
    expect(page.find("h1")).to have_text "You have added 2 answers"
    expect(page).to have_text first_answer_text
    expect(page).to have_text second_answer_text
  end

  def when_i_choose_not_to_add_another
    choose "No"
  end

  def then_i_should_see_the_check_your_answers_page
    expect(page.find("h1")).to have_text "Check your answers before submitting your form"
    expect(page).to have_text question_text
    expect(page).to have_text first_answer_text
    expect(page).to have_text second_answer_text
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
end
