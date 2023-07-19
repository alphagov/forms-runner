require "rails_helper"

RSpec.describe Question::DateComponent::View, type: :component do
  let(:question_page) { build :page, :with_date_settings, input_type: }
  let(:input_type) { "other_date" }
  let(:answer_text) { nil }
  let(:question) { DataStruct.new(date: answer_text, question_text: question_page.question_text, hint_text: question_page.hint_text, answer_settings:) }
  let(:answer_settings) { question_page.answer_settings }
  let(:extra_question_text_suffix) { nil }
  let(:form_builder) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    render_inline(described_class.new(form_builder:, question:, extra_question_text_suffix:))
  end

  describe "when component is other date field" do
    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders 3 text fields (day, month, year)" do
      expect(page).to have_css("input[type='text'][name='form[date(3i)]']")
      expect(page).to have_css("input[type='text'][name='form[date(2i)]']")
      expect(page).to have_css("input[type='text'][name='form[date(1i)]']")
    end

    it "does not contain autocomplete attributes" do
      expect(page).not_to have_css("input[type='text'][autocomplete='bday-day']")
      expect(page).not_to have_css("input[type='text'][autocomplete='bday-month']")
      expect(page).not_to have_css("input[type='text'][autocomplete='bday-year']")
    end

    context "when the user has provided an answer" do
      let(:answer_text) { Date.new(2023, 1, 31) }

      it "sets the 3 text fields (day,month, year) value" do
        expect(page.find("input[type='text'][name='form[date(3i)]']").value).to eq "31"
        expect(page.find("input[type='text'][name='form[date(2i)]']").value).to eq "1"
        expect(page.find("input[type='text'][name='form[date(1i)]']").value).to eq "2023"
      end
    end

    context "when the question has hint text" do
      let(:question_page) { build :page, :with_hints, :with_date_settings, input_type: }

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
      let(:question_page) { build :page, :with_date_settings, input_type:, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end
  end

  describe "when component is date of birth field" do
    let(:input_type) { "date_of_birth" }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders 3 text fields (day, month, year)" do
      expect(page).to have_css("input[type='text'][name='form[date(3i)]']")
      expect(page).to have_css("input[type='text'][name='form[date(2i)]']")
      expect(page).to have_css("input[type='text'][name='form[date(1i)]']")
    end

    it "does contain autocomplete attributes" do
      expect(page).to have_css("input[type='text'][autocomplete='bday-day']")
      expect(page).to have_css("input[type='text'][autocomplete='bday-month']")
      expect(page).to have_css("input[type='text'][autocomplete='bday-year']")
    end

    context "when the user has provided an answer" do
      let(:answer_text) { Date.new(2023, 1, 31) }

      it "sets the 3 text fields (day,month, year) value" do
        expect(page.find("input[type='text'][name='form[date(3i)]']").value).to eq "31"
        expect(page.find("input[type='text'][name='form[date(2i)]']").value).to eq "1"
        expect(page.find("input[type='text'][name='form[date(1i)]']").value).to eq "2023"
      end
    end

    context "when the question has hint text" do
      let(:question_page) { build :page, :with_hints, :with_date_settings, input_type: }

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
      let(:question_page) { build :page, :with_date_settings, input_type:, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end
  end

  context "when answer_settings is nil - behaves like other dates" do
    let(:answer_settings) { nil }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders 3 text fields (day, month, year)" do
      expect(page).to have_css("input[type='text'][name='form[date(3i)]']")
      expect(page).to have_css("input[type='text'][name='form[date(2i)]']")
      expect(page).to have_css("input[type='text'][name='form[date(1i)]']")
    end

    it "does not contain autocomplete attributes" do
      expect(page).not_to have_css("input[type='text'][autocomplete='bday-day']")
      expect(page).not_to have_css("input[type='text'][autocomplete='bday-month']")
      expect(page).not_to have_css("input[type='text'][autocomplete='bday-year']")
    end
  end
end
