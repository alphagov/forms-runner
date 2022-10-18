require "rails_helper"

describe "forms/check_your_answers/show.html.erb" do
  let(:context) { OpenStruct.new(form_id: 1, form_slug: "slug", mode: "", name: "Form 1") }

  before do
    assign(:current_context, context)
    assign(:form_submit_path, "/")
    render template: "forms/check_your_answers/show"
  end

  context "when the form does not have a declaration" do
    it "does not display the declaration heading" do
      expect(rendered).not_to have_css("h2", text: "Declaration")
    end
  end

  context "when the form has a declaration" do
    let(:context) { OpenStruct.new(id: 1, name: "Form 1", declaration_text: "You should agree to all terms before submitting") }

    it "displays the declaration heading" do
      expect(rendered).to have_css("h2", text: "Declaration")
    end

    it "displays declaration text" do
      expect(rendered).to have_css("p.govuk-body", text: "You should agree to all terms before submitting")
    end
  end
end
