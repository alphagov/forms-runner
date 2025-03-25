require "rails_helper"

RSpec.describe NotifyTemplateFormatter, type: :model do
  subject(:notify_template_formatter) { described_class.new }

  describe "#build_question_answers_section" do
    let(:completed_steps) { [step] }

    let(:step) { instance_double(Step, { id: 99, question_text: "What is the meaning of life?", show_answer_in_email: "42" }) }

    it "returns combined title and answer" do
      expect(notify_template_formatter.build_question_answers_section(completed_steps)).to eq "# What is the meaning of life?\n42\n"
    end

    context "when there is more than one step" do
      let(:completed_steps) { [step, step] }

      it "contains a horizontal rule between each step" do
        expect(notify_template_formatter.build_question_answers_section(completed_steps)).to include "\n\n---\n\n"
      end
    end

    context "when there is an error formatting an answer" do
      before do
        allow(step).to receive(:show_answer_in_email).and_raise(NoMethodError, "undefined method 'strip' for an instance of Array")
      end

      it "raises an error with the page id" do
        expect {
          notify_template_formatter.build_question_answers_section(completed_steps)
        }.to raise_error(NotifyTemplateFormatter::FormattingError, "could not format answer for question page 99")
      end
    end
  end

  describe "#prep_question_title" do
    it "returns markdown heading on its own line" do
      ["Hello", "3.4 Question", "-23.4 Negative headings", "\n\n # 4.5.6"].each do |title|
        page = instance_double(Step, question_text: title)
        expect(notify_template_formatter.prep_question_title(page)).to eq "# #{title}\n"
      end
    end
  end

  describe "#prep_answer_text" do
    it "returns escaped answer" do
      [
        { input: "Hello", output: "Hello" },
        { input: "3.4 Question", output: "3\\.4 Question" },
        { input: "-23.4 answer", output: "\\-23\\.4 answer" },
        { input: "4.5.6", output: "4\\.5\\.6" },
        { input: "\n\n# Test \n\n## Test 2", output: "\\# Test\n\n\\#\\# Test 2" },
        { input: "\n\n```# Test 3\n\n## Test 4", output: "\\`\\`\\`\\# Test 3\n\n\\#\\# Test 4" }, # escapes ```
        { input: "\n\n\n\n\n```# Test \n\n\n\n\n\n## Test 3\n\n\n\n", output: "\\`\\`\\`\\# Test\n\n\\#\\# Test 3" },
        { input: "test https://example.org # more text 19.5\n\nA new paragraph.", output: "test https://example.org \\# more text 19\\.5\n\nA new paragraph\\." },
        { input: "test https://example.org # more text 19.5\n\nA new paragraph.\n\n# another link http://gov.uk", output: "test https://example.org \\# more text 19\\.5\n\nA new paragraph\\.\n\n\\# another link http://gov.uk" },
        { input: "not a title\n====", output: "not a title\n\\_\\_\\_\\_" },
        { input: "a normal sentence: 10 = 5 + 5", output: "a normal sentence: 10 = 5 \\+ 5" },
        { input: "    paragraph 1\n\n\n\n\n\n\n\n\n\n\n\n\n Another Paragraph with trailing space     \n\n\n\n\n", output: "paragraph 1\n\nAnother Paragraph with trailing space" },

      ].each do |test_case|
        page = instance_double(Step, show_answer_in_email: test_case[:input])
        expect(notify_template_formatter.prep_answer_text(page)).to eq test_case[:output]
      end
    end

    context "when answer is blank i.e skipped" do
      let(:page) { instance_double(Step, show_answer_in_email: "") }

      it "returns the blank answer text" do
        expect(notify_template_formatter.prep_answer_text(page)).to eq "\\[This question was skipped\\]"
      end
    end
  end
end
