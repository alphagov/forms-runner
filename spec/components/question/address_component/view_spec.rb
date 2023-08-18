require "rails_helper"

RSpec.describe Question::AddressComponent::View, type: :component do
  let(:extra_question_text_suffix) { nil }
  let(:form_builder) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end

  before do
    render_inline(described_class.new(form_builder:, question:, extra_question_text_suffix:))
  end

  describe "when component is UK Address field" do
    let(:question) { build :uk_address_question }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders 5 text fields (Address line 1, Address line 2, Town or city, County, Postcode) and include autocomplete" do
      expect(page.find_all("input[type='text']").length).to eq 5
      expect(page).to have_css("input[type='text'][name='form[address1]'][autocomplete='address-line1']")
      expect(page).to have_css("input[type='text'][name='form[address2]'][autocomplete='address-line2']")
      expect(page).to have_css("input[type='text'][name='form[town_or_city]'][autocomplete='address-level2']")
      expect(page).to have_css("input[type='text'][name='form[county]']")
      expect(page).to have_css("input[type='text'][name='form[postcode]'][autocomplete='postal-code']")
    end

    context "when the question has hint text" do
      let(:question) { build :uk_address_question, :with_hints }

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
      let(:question) { build :uk_address_question, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end
  end

  describe "when component is international address field" do
    let(:question) { build :international_address_question }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders 1 textarea (Street Address and 1 input(Country) and includes autocomplete" do
      expect(page.find_all("textarea").length).to eq 1
      expect(page.find_all("input[type='text']").length).to eq 1
      expect(page).to have_css("textarea[name='form[street_address]'][autocomplete='street-address']")
      expect(page).to have_css("input[type='text'][name='form[country]'][autocomplete='country-name']")
    end

    context "when the question has hint text" do
      let(:question) { build :international_address_question, :with_hints }

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
      let(:question) { build :international_address_question, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end
  end

  describe "when component is UK & international address field" do
    let(:question) { build :address }

    it "renders the question text as a heading" do
      expect(page.find("h1")).to have_text(question.question_text)
    end

    it "renders 1 textarea (Street Address and 1 input(Country) and includes autocomplete" do
      expect(page.find_all("textarea").length).to eq 1
      expect(page.find_all("input[type='text']").length).to eq 1
      expect(page).to have_css("textarea[name='form[street_address]'][autocomplete='street-address']")
      expect(page).to have_css("input[type='text'][name='form[country]'][autocomplete='country-name']")
    end

    context "when the question has hint text" do
      let(:question) { build :international_address_question, :with_hints }

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
      let(:question) { build :international_address_question, question_text: "What is your name? <script>alert(\"Hi\")</script>" }
      let(:extra_question_text_suffix) { "<span>Some trusted html</span>" }

      it "returns the escaped title with the optional suffix" do
        expected_output = "What is your name? &lt;script&gt;alert(\"Hi\")&lt;/script&gt; <span>Some trusted html</span>"
        expect(page.find("h1").native.inner_html).to eq(expected_output)
      end
    end
  end
end
