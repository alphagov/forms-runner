require "rails_helper"

RSpec.describe SesEmailFormatter do
  describe "#build_question_answers_section_html" do
    let(:text_question) { build :text, question_text: "What is the meaning of life?", text: "42" }
    let(:text_step) { build :step, question: text_question }
    let(:name_question) { build :first_middle_last_name_question, question_text: "What is your name?" }
    let(:name_step) { build :step, question: name_question }
    let(:completed_steps) { [text_step] }

    context "when there is one step" do
      it "returns question and and answer HTML" do
        question_answers = described_class.new.build_question_answers_section_html(completed_steps)
        expect(question_answers).to eq("<h2>What is the meaning of life?</h2><p>42</p>")
      end
    end

    context "when the answer has multiple attributes" do
      let(:completed_steps) { [name_step] }

      it "inserts line breaks between answer attributes" do
        question_answers = described_class.new.build_question_answers_section_html(completed_steps)
        expect(question_answers).to eq("<h2>What is your name?</h2><p>First name: #{name_question.first_name}<br/><br/>Last name: #{name_question.last_name}</p>")
      end
    end

    context "when the answer is blank i.e. skipped" do
      let(:text_question) { build :text, question_text: "What is the meaning of life?", text: nil }
      let(:completed_steps) { [text_step] }

      it "returns the blank answer text" do
        question_answers = described_class.new.build_question_answers_section_html(completed_steps)
        expect(question_answers).to eq("<h2>What is the meaning of life?</h2><p>[This question was skipped]</p>")
      end
    end

    context "when there is more than one step" do
      let(:completed_steps) { [text_step, name_step] }

      it "returns all question an answers separated by a horizontal rule" do
        question_answers = described_class.new.build_question_answers_section_html(completed_steps)
        expect(question_answers).to eq("<h2>What is the meaning of life?</h2><p>42</p><hr style=\"border: 0; height: 1px; background: #B1B4B6; Margin: 30px 0 30px 0;\"><h2>What is your name?</h2><p>First name: #{name_question.first_name}<br/><br/>Last name: #{name_question.last_name}</p>")
      end
    end

    context "when there are special characters in the answer" do
      let(:completed_steps) { [text_step] }

      it "returns the sanitized answer" do
        [
          { input: "\n\nTest\n\nTest 2", output: "Test<br/><br/>Test 2" },
          { input: "    paragraph 1\n\n\n\n\n\n\n\n\n\n\n\n\n Another Paragraph with trailing space     \n\n\n\n\n", output: "paragraph 1<br/><br/>Another Paragraph with trailing space" },

        ].each do |test_case|
          text_question.text = test_case[:input]

          question_answers = described_class.new.build_question_answers_section_html(completed_steps)
          expect(question_answers).to eq("<h2>What is the meaning of life?</h2><p>#{test_case[:output]}</p>")
        end
      end
    end

    context "when there is an error formatting an answer" do
      before do
        text_step.page.id = 99
        allow(text_step).to receive(:show_answer_in_email).and_raise(NoMethodError, "undefined method 'strip' for an instance of Array")
      end

      it "raises an error with the page id" do
        expect {
          described_class.new.build_question_answers_section_html(completed_steps)
        }.to raise_error(SesEmailFormatter::FormattingError, "could not format answer for question page 99")
      end
    end
  end

  describe "#build_question_answers_section_plain_text" do
    let(:text_question) { build :text, question_text: "What is the meaning of life?", text: "42" }
    let(:text_step) { build :step, question: text_question }
    let(:name_question) { build :first_middle_last_name_question, question_text: "What is your name?" }
    let(:name_step) { build :step, question: name_question }
    let(:completed_steps) { [text_step] }

    context "when there is one step" do
      it "returns question and and answer HTML" do
        question_answers = described_class.new.build_question_answers_section_plain_text(completed_steps)
        expect(question_answers).to eq("What is the meaning of life?\n\n42")
      end
    end

    context "when the answer has multiple attributes" do
      let(:completed_steps) { [name_step] }

      it "inserts line breaks between answer attributes" do
        question_answers = described_class.new.build_question_answers_section_plain_text(completed_steps)
        expect(question_answers).to eq("What is your name?\n\nFirst name: #{name_question.first_name}\n\nLast name: #{name_question.last_name}")
      end
    end

    context "when the answer is blank i.e. skipped" do
      let(:text_question) { build :text, question_text: "What is the meaning of life?", text: nil }
      let(:completed_steps) { [text_step] }

      it "returns the blank answer text" do
        question_answers = described_class.new.build_question_answers_section_plain_text(completed_steps)
        expect(question_answers).to eq("What is the meaning of life?\n\n[This question was skipped]")
      end
    end

    context "when there is more than one step" do
      let(:completed_steps) { [text_step, name_step] }

      it "returns all question an answers separated by a horizontal rule" do
        question_answers = described_class.new.build_question_answers_section_plain_text(completed_steps)
        expect(question_answers).to eq("What is the meaning of life?\n\n42\n\n---\n\nWhat is your name?\n\nFirst name: #{name_question.first_name}\n\nLast name: #{name_question.last_name}")
      end
    end

    context "when there are special characters in the answer" do
      let(:completed_steps) { [text_step] }

      it "returns the sanitized answer" do
        [
          { input: "\n\nTest\n\nTest 2", output: "Test\n\nTest 2" },
          { input: "    paragraph 1\n\n\n\n\n\n\n\n\n\n\n\n\n Another Paragraph with trailing space     \n\n\n\n\n", output: "paragraph 1\n\nAnother Paragraph with trailing space" },

        ].each do |test_case|
          text_question.text = test_case[:input]

          question_answers = described_class.new.build_question_answers_section_plain_text(completed_steps)
          expect(question_answers).to eq("What is the meaning of life?\n\n#{test_case[:output]}")
        end
      end
    end

    context "when there is an error formatting an answer" do
      before do
        text_step.page.id = 99
        allow(text_step).to receive(:show_answer_in_email).and_raise(NoMethodError, "undefined method 'strip' for an instance of Array")
      end

      it "raises an error with the page id" do
        expect {
          described_class.new.build_question_answers_section_plain_text(completed_steps)
        }.to raise_error(SesEmailFormatter::FormattingError, "could not format answer for question page 99")
      end
    end
  end
end
