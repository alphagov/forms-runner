require "rails_helper"

feature "Email confirmation", type: :feature do
  let(:steps) { [build(:v2_question_page_step, :with_text_settings, id: 1, routing_conditions: [], question_text:)] }
  let(:form) { build :v2_form_document, :live?, id: 1, name: "Apply for a juggling license", steps:, start_page: 1 }
  let(:question_text) { Faker::Lorem.question }
  let(:text_answer) { Faker::Lorem.sentence }

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
  end

  scenario "opting out of email submission returns the confirmation page without confirmation email text" do
    fill_in_form
    choose "No", visible: false
    click_button "Submit"
    expect(page.find("h1")).to have_text I18n.t("form.submitted.title")
    expect(page).not_to have_text I18n.t("form.submitted.email_sent")
  end

  scenario "opting in to email submission returns the confirmation page with confirmation email text" do
    fill_in_form
    choose "Yes", visible: false
    fill_in "What email address do you want us to send your confirmation to?", with: "example@example.gov.uk"
    click_button "Submit"
    expect(page.find("h1")).to have_text I18n.t("form.submitted.title")
    expect(page).to have_text I18n.t("form.submitted.email_sent")
  end

  def fill_in_form
    visit form_path(mode: "form", form_id: 1, form_slug: "apply-for-a-juggling-licence")
    expect(page.find("h1")).to have_text question_text
    expect_page_to_have_no_axe_errors(page)

    fill_in question_text, with: text_answer
    click_button "Continue"
    expect(page.find("h1")).to have_text I18n.t("form.check_your_answers.title")
    expect(page).to have_text question_text
    expect(page).to have_text text_answer
  end
end
