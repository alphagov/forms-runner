require "rails_helper"

feature "Email confirmation", type: :feature do
  let(:pages) { [(build :page, :with_text_settings, id: 1, form_id: 1, routing_conditions: [])] }
  let(:form) { build :form, :live?, id: 1, name: "Apply for a juggling license", pages:, start_page: 1 }
  let(:text_answer) { Faker::Lorem.sentence }

  before do
    allow(FormService).to receive(:find_with_mode).with(any_args).and_raise(ActiveResource::ResourceNotFound.new(404, "Not Found"))
    allow(FormService).to receive(:find_with_mode).with(id: "1", mode: kind_of(Mode)).and_return(form)
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
    expect(page.find("h1")).to have_text pages[0].question_text
    expect_page_to_have_no_axe_errors(page)

    fill_in pages[0].question_text, with: text_answer
    click_button "Continue"
    expect(page.find("h1")).to have_text I18n.t("form.check_your_answers.title")
    expect(page).to have_text pages[0].question_text
    expect(page).to have_text text_answer
  end
end
