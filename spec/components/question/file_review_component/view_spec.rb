require "rails_helper"

RSpec.describe Question::FileReviewComponent::View, type: :component do
  let(:question_page) { build :page, answer_type: "file" }
  let(:is_optional) { false }
  let(:question_text) { "Upload a file" }
  let(:page_heading) { nil }
  let(:hint_text) { nil }
  let(:question) { build :file, :with_uploaded_file, question_text:, is_optional:, page_heading:, hint_text: }
  let(:extra_question_text_suffix) { nil }
  let(:remove_file_confirmation_url) { "/remove_file_confirmation" }

  before do
    render_inline(described_class.new(question:, extra_question_text_suffix:, remove_file_confirmation_url:))
  end

  it "renders the question text as a h1" do
    expect(page.find("h1")).to have_text(question.question_text_with_optional_suffix)
  end

  context "when the question has hint text" do
    let(:hint_text) { Faker::Lorem.sentence }

    it "outputs the hint text" do
      expect(page.find(".govuk-hint")).to have_text(hint_text)
    end
  end

  context "when the question has no hint text" do
    it "does not output the hint text" do
      expect(page).not_to have_css(".govuk-hint")
    end
  end

  it "renders the original file name" do
    expect(page).to have_content(question.original_filename)
  end

  it "has a link to the file removal confirmation page" do
    expect(page).to have_link(I18n.t("forms.review_file.show.remove"), href: remove_file_confirmation_url)
  end

  it "the link to the file removal confirmation page has hidden text" do
    expect(page).to have_css(".govuk-visually-hidden", text: I18n.t("forms.review_file.show.your_file"))
  end

  context "when there is an extra suffix to be added to the heading" do
    let(:extra_question_text_suffix) { "Some extra text to add to the question text" }

    it "renders the question text and extra suffix as a heading" do
      expect(page.find("h1")).to have_text("#{question.question_text} #{extra_question_text_suffix}")
    end
  end

  context "with unsafe question text" do
    let(:question_text) { "What is your name? <script>alert(\"Hi\")</script>" }
    let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

    it "returns the escaped title with the optional suffix" do
      expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
      expect(page.find("h1").native.inner_html).to eq(expected_output)
    end
  end

  it "has text to explain the file can be removed" do
    expect(page).to have_content(I18n.t("forms.review_file.show.remove_file_guidance"))
  end
end
