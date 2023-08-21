require "rails_helper"

RSpec.describe GuidanceComponent::View, type: :component do
  let(:answer_text) { nil }
  let(:page_heading) { "10 figure grid reference of the proposed location of the building" }
  let(:subheading) { "How to find your 10 figure grid reference" }
  let(:guidance_markdown) { "## #{subheading}" }
  let(:question) { OpenStruct.new(page_heading:, guidance_markdown:) }

  before do
    render_inline(described_class.new(question))
  end

  context "when page_heading is blank" do
    let(:page_heading) { nil }

    it "does not render" do
      expect(page).not_to have_css("*")
    end
  end

  context "when guidance_markdown is blank" do
    let(:guidance_markdown) { nil }

    it "does not render" do
      expect(page).not_to have_css("*")
    end
  end

  describe "when component has a page heading and guidance markdown" do
    it "renders the page_heading as a h1" do
      expect(page.find("h1.govuk-heading-l")).to have_text(question.page_heading)
    end

    it "renders the markdown correctly" do
      # just test that markdown is rendered on the page - we test the markdown rendering in more detail within the govuk-forms-markdown gem itself
      expect(page.find("h2")).to have_text(subheading)
    end

    context "with unsafe question text" do
      let(:page_heading) { "10 figure grid reference of the proposed location of the building<script>alert(\"Hi\")</script>" }
      let(:guidance_markdown) { "<script>alert(\"Hi\")</script>" }

      it "does not render the script element" do
        expect(page).not_to have_css("script")
      end
    end
  end
end
