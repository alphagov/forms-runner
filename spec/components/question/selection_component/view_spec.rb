require "rails_helper"

RSpec.describe Question::SelectionComponent::View, type: :component do
  let(:only_one_option) { "false" }
  let(:is_optional) { false }
  let(:answer_text) { nil }
  let(:extra_question_text_suffix) { nil }
  let(:form_builder) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    render_inline(described_class.new(form_builder:, question:, extra_question_text_suffix:))
  end

  shared_examples "None of the above question field" do
    context "when a 'None of the above' question is not defined" do
      it "does not render a conditional text field for the 'None of the above' option" do
        expect(page).not_to have_css("input[type='text'][name='form[none_of_the_above_answer]']")
      end
    end

    context "when a 'None of the above' question is defined" do
      let(:none_of_the_above_question_text_is_optional) { "true" }
      let(:question) do
        build(:single_selection_question,
              :with_none_of_the_above_question,
              none_of_the_above_question_text: "Enter another answer",
              none_of_the_above_question_text_is_optional:)
      end

      it "renders a conditional text field for the 'None of the above' option" do
        expect(page).to have_css("input[type='text'][name='form[none_of_the_above_answer]']")
      end

      context "when the 'None of the above' question is optional" do
        it "has the question text with an optional suffix as the label for the field" do
          expect(page).to have_css("label[for='form-none-of-the-above-answer-field']", text: "Enter another answer (optional)")
        end
      end

      context "when the 'None of the above' question is mandatory" do
        let(:none_of_the_above_question_text_is_optional) { "false" }

        it "has the question text as the label for the field" do
          expect(page).to have_css("label[for='form-none-of-the-above-answer-field']", text: "Enter another answer")
        end
      end
    end
  end

  describe "when component is select one from a list field" do
    context "when there are 30 or fewer options" do
      let(:question) { build :single_selection_question, is_optional:, selection_options: }

      let(:selection_options) do
        Array.new(30).map { |_index| OpenStruct.new(name: Faker::Lorem.sentence) }
      end

      it "renders the question text as a heading" do
        expect(page.find("legend h1")).to have_text(question.question_text)
      end

      it "renders the options as radio buttons" do
        expect(page).not_to have_select

        selection_options.each do |option|
          expect(page).to have_field(type: "radio", with: option.name)
        end
      end

      context "when the question has hint text" do
        let(:question) { build :single_selection_question, :with_hints, selection_options: }

        it "outputs the hint text" do
          expect(page.find(".govuk-hint")).to have_text(question.hint_text)
        end
      end

      context "when there is extra suffix to be added to heading" do
        let(:extra_question_text_suffix) { "Some extra text to add to the question text" }

        it "renders the question text and extra suffix as a heading" do
          expect(page.find("legend h1")).to have_text("#{question.question_text} #{extra_question_text_suffix}")
        end
      end

      context "with unsafe question text" do
        let(:question) { build :single_selection_question, question_text: "What is your name? <script>alert(\"Hi\")</script>", selection_options: }
        let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

        it "returns the escaped title with the optional suffix" do
          expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
          expect(page.find("h1").native.inner_html).to eq(expected_output)
        end
      end

      context "when question is optional" do
        let(:is_optional) { true }

        it "does a legend with only the question text in and not suffixed with '(optional)'" do
          expect(page.find("h1")).to have_text(question.question_text)
        end

        it "contains the 'None of the above' option" do
          expect(page).to have_css("input[type='radio'] + label", text: "None of the above")
        end

        include_examples "None of the above question field"
      end

      context "when question has guidance" do
        let(:question) { build :single_selection_question, :with_guidance, selection_options: }

        it "renders the question text as a legend" do
          expect(page.find("legend.govuk-fieldset__legend--m")).to have_text(question.question_text)
        end
      end
    end

    context "when there are more than 30 options" do
      let(:question) { build :single_selection_question, is_optional:, selection_options: }

      let(:selection_options) do
        Array.new(31).map { |_index| OpenStruct.new(name: Faker::Lorem.sentence) }
      end

      let(:selection_option_names) { selection_options.map(&:name) }

      context "when 'None of the above' is not enabled" do
        let(:is_optional) { false }

        it "renders the question as a select field with a prompt and all of the options" do
          expected_options = [I18n.t("autocomplete.prompt"), *selection_option_names]
          expect(page).to have_select(question.question_text, options: expected_options)
        end
      end

      context "when 'None of the above' is enabled" do
        let(:is_optional) { true }

        it "renders the question as a select field with a prompt, all of the options and a 'None of the above' option" do
          expected_options = [I18n.t("autocomplete.prompt"), *selection_option_names, I18n.t("page.none_of_the_above")]

          expect(page).to have_select(question.question_text, options: expected_options)
        end
      end

      it "renders the question text as a heading" do
        expect(page.find("h1")).to have_text(question.question_text)
      end

      context "when the question has hint text" do
        let(:question) { build :single_selection_question, :with_hints, selection_options: }

        it "outputs the hint text" do
          expect(page.find(".govuk-hint")).to have_text(question.hint_text)
        end
      end

      context "when there is extra suffix to be added to heading" do
        let(:extra_question_text_suffix) { "Some extra text to add to the question text" }

        it "renders the question text and extra suffix as a heading" do
          expect(page.find("h1")).to have_text("#{question.question_text} #{extra_question_text_suffix}")
        end
      end

      context "with unsafe question text" do
        let(:question) { build :single_selection_question, question_text: "What is your name? <script>alert(\"Hi\")</script>", selection_options: }
        let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

        it "returns the escaped title with the optional suffix" do
          expected_output = "<label for=\"form-selection-field\" class=\"govuk-label govuk-label--l\">What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span></label>"
          expect(page.find("h1").native.inner_html).to eq(expected_output)
        end
      end

      context "when question has guidance" do
        let(:question) { build :single_selection_question, :with_guidance, selection_options: }

        it "renders the question text as a legend" do
          expect(page.find("label")).to have_text(question.question_text)
        end
      end
    end
  end

  describe "when component is select multiple from a list field" do
    let(:question) { build :multiple_selection_question, is_optional: }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "contains the options" do
      expect(page).to have_css("input[type='checkbox'] + label", text: "Option 1")
      expect(page).to have_css("input[type='checkbox'] + label", text: "Option 2")
    end

    context "when the question has hint text" do
      let(:question) { build :multiple_selection_question, :with_hints }

      it "outputs the hint text" do
        expect(page.find(".govuk-hint")).to have_text(question.hint_text)
      end
    end

    context "when there is extra suffix to be added to heading" do
      let(:extra_question_text_suffix) { "Some extra text to add to the question text" }

      it "renders the question text and extra suffix as a heading" do
        expect(page.find("h1")).to have_text("#{question.question_text} #{extra_question_text_suffix}")
      end
    end

    context "with unsafe question text" do
      let(:question) { build :multiple_selection_question, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end

    context "when question is optional" do
      let(:is_optional) { true }

      it "does a legend with only the question text in and not suffixed with '(optional)'" do
        expect(page.find("h1")).to have_text(question.question_text)
      end

      it "contains the 'None of the above' option" do
        expect(page).to have_css("input[type='checkbox'] + label", text: "None of the above")
      end

      include_examples "None of the above question field"
    end

    context "when question has guidance" do
      let(:question) { build :multiple_selection_question, :with_guidance }

      it "renders the question text as a legend" do
        expect(page.find("legend.govuk-fieldset__legend--m")).to have_text(question.question_text)
      end
    end
  end
end
