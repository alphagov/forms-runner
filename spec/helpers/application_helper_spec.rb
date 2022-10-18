require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "page_title" do
    it "returns the title with the GOV.UK suffix" do
      helper.set_page_title("Test")
      expect(view.content_for(:title)).to eq("Test")
      expect(helper.page_title).to eq("Test – GOV.UK")
    end
  end

  describe "title_with_error_prefix" do
    context "with errors present" do
      it "returns the title with the error prefix" do
        expect(helper.title_with_error_prefix("Test", true)).to eq("Error: Test")
      end
    end

    context "with no errors present" do
      it "returns the title with no prefix" do
        expect(helper.title_with_error_prefix("Test", false)).to eq("Test")
      end
    end
  end

  describe "optional_label" do
    context "with an optional question" do
      it "returns the title with the optional suffix" do
        page = OpenStruct.new(question_text: "What is your name?", question: OpenStruct.new(is_optional?: true))
        expect(helper.optional_label(page)).to eq("What is your name? (optional)")
      end
    end

    context "with a required question" do
      it "returns the title with the optional suffix" do
        page = OpenStruct.new(question_text: "What is your name?", question: OpenStruct.new(is_optional?: false))
        expect(helper.optional_label(page)).to eq("What is your name?")
      end
    end
  end
end
