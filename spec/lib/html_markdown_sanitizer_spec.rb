require "rails_helper"

RSpec.describe HtmlMarkdownSanitizer do
  let(:answer_store) { described_class.new }
  let(:simple_multiline_string) { "This is a paragraph.\n\nThis is another paragraph.\nThis is a new line within the same paragraph" }
  let(:simple_string_with_disallowed_html) { "<script>alert(\"script\")</script>" }
  let(:multiline_html_string_with_disallowed_content) do
    "Check out the following list:\n\n"\
            "<script>alert(\"script\")</script>\n\n"\
            "<ol><li>this is a list item</li><li>this is another list item</li></ol>"
  end
  let(:multiline_markdown_string_with_disallowed_content) do
    "# This is a heading\n"\
            "\n\n"\
            "- this is a list item\n"\
            "- This is another list item\n"
  end

  describe "#format_paragraphs" do
    it "converts line breaks into <br> and <p> tags" do
      expect(answer_store.format_paragraphs(simple_multiline_string)).to eq("<p>This is a paragraph.</p>\n\n<p>This is another paragraph.\n<br />This is a new line within the same paragraph</p>")
    end

    it "escapes disallowed HTML characters" do
      expect(answer_store.format_paragraphs(simple_string_with_disallowed_html)).to eq "<p>&lt;script&gt;alert(\"script\")&lt;/script&gt;</p>"
    end

    it "escapes the HTML characters in a multiline string with disallowed HTML" do
      expect(answer_store.format_paragraphs(multiline_html_string_with_disallowed_content)).to eq("<p>Check out the following list:</p>\n\n<p>&lt;script&gt;alert(\"script\")&lt;/script&gt;</p>\n\n<p>&lt;ol&gt;&lt;li&gt;this is a list item&lt;/li&gt;&lt;li&gt;this is another list item&lt;/li&gt;&lt;/ol&gt;</p>")
    end
  end

  describe "#sanitize_html" do
    it "sanitizes the string" do
      expect(answer_store.sanitize_html(multiline_html_string_with_disallowed_content, LimitedHtmlScrubber.new)).to eq("Check out the following list:\n\nalert(\"script\")\n\n<ol><li>this is a list item</li><li>this is another list item</li></ol>")
    end
  end

  describe "#render_scrubbed_markdown" do
    it "converts line breaks into <p> tags" do
      expect(answer_store.render_scrubbed_markdown(simple_multiline_string)).to eq("<p class=\"govuk-body\">This is a paragraph.</p>\n<p class=\"govuk-body\">This is another paragraph.\nThis is a new line within the same paragraph</p>")
    end

    it "sanitizes any markdown supplied to it" do
      expect(answer_store.render_scrubbed_markdown(multiline_markdown_string_with_disallowed_content)).to eq("<p class=\"govuk-body\">This is a heading</p>\n<ul class=\"govuk-list govuk-list--bullet\">\n  <li>this is a list item</li>\n<li>This is another list item</li>\n\n</ul>")
    end

    it "escapes any HTML supplied to it" do
      expect(answer_store.render_scrubbed_markdown(simple_string_with_disallowed_html)).to eq("<p class=\"govuk-body\">&lt;script&gt;alert(\"script\")&lt;/script&gt;</p>")
    end
  end

  describe "#render_scrubbed_html" do
    it "converts line breaks into <p> tags" do
      expect(answer_store.render_scrubbed_html(simple_multiline_string)).to eq("<p>This is a paragraph.</p>\n\n<p>This is another paragraph.\n<br />This is a new line within the same paragraph</p>")
    end

    it "sanitizes the string" do
      expect(answer_store.render_scrubbed_html(multiline_html_string_with_disallowed_content)).to eq("<p>Check out the following list:</p>\n\n<p>alert(\"script\")</p>\n\n<p><ol><li>this is a list item</li><li>this is another list item</li></ol></p>")
    end
  end
end
