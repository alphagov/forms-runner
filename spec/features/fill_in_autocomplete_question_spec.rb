require "rails_helper"

feature "Fill in and submit a form with an autocomplete question", type: :feature do
  let(:steps) { [(build :v2_question_page_step, :with_selections_settings, id: 1, routing_conditions: [], question_text:, selection_options:)] }
  let(:form) { build :v2_form_document, :live?, form_id: 1, name: "Fill in this form", steps:, start_page: 1 }
  let(:selection_options) { Array.new(31).each_with_index.map { |_element, index| { name: "Answer #{index}" } } }
  let(:question_text) { Faker::Lorem.question }
  let(:answer_text) { "Answer 1" }
  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

  let(:req_headers) { { "Accept" => "application/json" } }
  let(:post_headers) { { "Content-Type" => "application/json" } }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/1/live", req_headers, form.to_json, 200
    end

    allow(ReferenceNumberService).to receive(:generate).and_return(reference)
  end

  scenario "As a form filler" do
    when_i_visit_the_form_start_page
    then_i_should_see_the_first_question

    when_i_start_filling_in_the_question
    then_i_should_see_the_options
    when_i_choose_an_option
    and_i_click_on_continue
    then_i_should_see_the_check_your_answers_page

    when_i_opt_out_of_email_confirmation
    and_i_submit_my_form
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

  def when_i_start_filling_in_the_question
    fill_in question_text, with: answer_text.slice(0, 3)
  end

  def then_i_should_see_the_options
    selection_options.each do |option|
      expect(page).to have_css('li[role="option"]', text: option[:name])
    end
  end

  def when_i_choose_an_option
    page.find('li[role="option"]', exact_text: answer_text).click
  end

  def and_i_click_on_continue
    click_button "Continue"
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

  def then_my_form_should_be_submitted
    expect(page.find("h1")).to have_text "Your form has been submitted"
    expect_page_to_have_no_axe_errors(page)
  end

  def and_i_should_receive_a_reference_number
    expect(page).to have_text reference
  end
end
