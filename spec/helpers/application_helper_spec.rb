require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#page_title" do
    context "when set_page_title is supplied with a single argument" do
      before do
        helper.set_page_title("Test")
      end

      it "returns the title with the GOV.UK suffix" do
        expect(view.content_for(:title)).to eq("Test")
      end
    end

    context "when set_page_title is supplied with multiple arguments" do
      before do
        helper.set_page_title("Test", t("gov_uk_forms"))
      end

      it "returns the title with the GOV.UK suffix" do
        expect(view.content_for(:title)).to eq("Test – GOV.UK Forms")
      end
    end
  end

  describe "#hidden_text_mode" do
    let(:mode) { OpenStruct.new(preview?: false) }

    it "returns empty string by default if not in some preview mode" do
      expect(helper.hidden_text_mode(mode)).to eq ""
    end

    context "when previewing in draft mode" do
      let(:mode) { OpenStruct.new(preview?: true, preview_draft?: true, preview_live?: false) }

      it "returns a visually hidden span with the mode name" do
        expect(helper.hidden_text_mode(mode)).to eq "<span class='govuk-visually-hidden'>&nbsp;draft preview</span>"
      end
    end

    context "when previewing in live mode" do
      let(:mode) { OpenStruct.new(preview?: true, preview_draft?: false, preview_live?: true) }

      it "returns a visually hidden span with the mode name" do
        expect(helper.hidden_text_mode(mode)).to eq "<span class='govuk-visually-hidden'>&nbsp;live preview</span>"
      end
    end
  end

  describe "#form_title" do
    context "when there is no error" do
      context "when in live mode" do
        it "returns the only the page title" do
          mode = OpenStruct.new("live?": true, "preview_draft?": false, "preview_live?": false)
          expect(helper.form_title(form_name: "form-name", page_name: "page title", mode:)).to eq("page title - form-name")
        end
      end

      context "when in preview draft mode" do
        it "returns the page title and mode" do
          mode = OpenStruct.new("live?": false, "preview_draft?": true, "preview_live?": false)
          expect(helper.form_title(form_name: "form-name", page_name: "page title", mode:)).to eq("page title - Draft preview - form-name")
        end
      end

      context "when in preview live mode" do
        it "returns the page title and mode" do
          mode = OpenStruct.new("live?": false, "preview_draft?": false, "preview_live?": true)
          expect(helper.form_title(form_name: "form-name", page_name: "page title", mode:)).to eq("page title - Live preview - form-name")
        end
      end
    end

    context "when an error is present" do
      it "returns page error and page title when in live mode" do
        mode = OpenStruct.new("live?": true, "preview_draft?": false, "preview_live?": false)
        expect(helper.form_title(form_name: "form-name", page_name: "page title", mode:, error: true)).to eq("Error: page title - form-name")
      end

      it "returns the error, page title and mode when in preview draft mode" do
        mode = OpenStruct.new("live?": false, "preview_draft?": true, "preview_live?": false)
        expect(helper.form_title(form_name: "form-name", page_name: "page title", mode:, error: true)).to eq("Error: page title - Draft preview - form-name")
      end

      it "returns the error, page title and mode when in preview live mode" do
        mode = OpenStruct.new("live?": false, "preview_draft?": false, "preview_live?": true)
        expect(helper.form_title(form_name: "form-name", page_name: "page title", mode:, error: true)).to eq("Error: page title - Live preview - form-name")
      end
    end
  end

  describe "#format_paragraphs" do
    it "splits text into paragraphs and encodes HTML characters" do
      expect(helper.format_paragraphs("Paragraph 1\n\n<h2>paragraph 2</h2>")).to eq "<p>Paragraph 1</p>\n\n<p>&lt;h2&gt;paragraph 2&lt;/h2&gt;</p>"
    end
  end

  describe "#init_autocomplete_script" do
    before do
      helper.init_autocomplete_script
    end

    it "returns the autocomplete script" do
      expect(view.content_for(:body_end)).to include("
      document.addEventListener('DOMContentLoaded', function(event) {
        if(window.dfeAutocomplete !== undefined && typeof window.dfeAutocomplete === 'function') {
          dfeAutocomplete({
            showAllValues: true,
            rawAttribute: false,
            source: false,
            autoselect: false,
            tNoResults: () => 'No results found',
            tStatusQueryTooShort: (minQueryLength) => `Type in ${minQueryLength} or more characters for results`,
            tStatusNoResults: () => 'No search results',
            tStatusSelectedOption: (selectedOption, length, index) => `${selectedOption} ${index + 1} of ${length} is highlighted`,
            tStatusResults: (length, contentSelectedOption) => (length === 1 ? `${length} result is available. ${contentSelectedOption}` : `${length} results are available. ${contentSelectedOption}`),
            tAssistiveHint: () => 'When autocomplete results are available use up and down arrows to review and enter to select.  Touch device users, explore by touch or with swipe gestures.',
          })
        }
      });")
    end
  end
end
