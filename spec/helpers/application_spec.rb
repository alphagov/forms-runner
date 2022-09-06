require "rails_helper"

RSpec.describe ApplicationHelper, :type => :helper do
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

    context "with errors present" do
      it "returns the title with no prefix" do
        expect(helper.title_with_error_prefix("Test", false)).to eq("Test")
      end
    end
  end
end
