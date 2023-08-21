require "rails_helper"

RSpec.describe MarkdownScrubber do
  let(:markdown_scrubber) { described_class.new }

  it "returns an array of html tags allowed" do
    expect(markdown_scrubber.tags).to eq %w[a h2 h3 ol ul li p]
  end

  it "returns an array of html attributes allowed" do
    expect(markdown_scrubber.attributes).to eq %w[href class rel target title]
  end

  context "when used with sanitize" do
    context "when the string contains only allowed markup" do
      let(:input) { "<a href=\"#\">A perfectly innocent link</a>" }

      it "returns the allowed markup unchanged" do
        sanitized_string = ActionController::Base.helpers.sanitize(input, scrubber: markdown_scrubber)
        expect(sanitized_string).to eq "<a href=\"#\">A perfectly innocent link</a>"
      end
    end

    context "when the string contains an allowed tag with a disallowed attribute" do
      let(:input) { "<a href=\"#\" class=\"govuk-link\" target=\"blank\" rel=\"noopener noreferrer\" style=\"color: rebeccapurple\" onClick=\"alert('some malicious js!')\">A link with some dodgy styling and JS attached</a>" }

      it "returns the tag with the disallowed attributes removed" do
        sanitized_string = ActionController::Base.helpers.sanitize(input, scrubber: markdown_scrubber)
        expect(sanitized_string).to eq "<a href=\"#\" class=\"govuk-link\" target=\"blank\" rel=\"noopener noreferrer\">A link with some dodgy styling and JS attached</a>"
      end
    end

    context "when the string contains disallowed markup" do
      let(:input) { "<a href=\"#\"><em>A</em> <strong class=\"bold\">perfectly</strong> <b style=\"font-weight: 700;\">innocent</b> <i>link</i></a><script>alert(\"malicious code!\")</script>" }

      it "sanitises the disallowed markup" do
        sanitized_string = ActionController::Base.helpers.sanitize(input, scrubber: markdown_scrubber)
        expect(sanitized_string).to eq "<a href=\"#\">A perfectly innocent link</a>alert(\"malicious code!\")"
      end
    end
  end
end
