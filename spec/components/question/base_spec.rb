require "rails_helper"

RSpec.describe Question::Base, type: :component do
  let(:mode) { Mode.new("form") }
  let(:form_builder) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                  ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
  end
  let(:page_heading) { "National insurance number" }
  let(:guidance_markdown) { "## National insurance number\n\nYou can find this on your National insurance card." }
  let(:question) { build :full_name_question, page_heading:, guidance_markdown: }

  let(:question_base) { described_class.new(form_builder:, question:, mode:) }

  describe "#question_text_size_and_tag" do
    context "when both guidance fields are present" do
      it "returns config for a medium default tag" do
        expect(question_base.question_text_size_and_tag).to eq({ size: "m" })
      end
    end

    context "when page_heading is present but the page heading is nil" do
      let(:page_heading) { nil }

      it "returns config for a medium default tag" do
        expect(question_base.question_text_size_and_tag).to eq({ size: "m" })
      end
    end

    context "when page_heading is present but the guidance markdown is nil" do
      let(:guidance_markdown) { nil }

      it "returns config for a medium default tag" do
        expect(question_base.question_text_size_and_tag).to eq({ size: "m" })
      end
    end

    context "when the page heading is empty but the guidance markdown is present" do
      let(:page_heading) { "" }

      it "returns config for a medium default tag" do
        expect(question_base.question_text_size_and_tag).to eq({ size: "m" })
      end
    end

    context "when the guidance markdown is empty but the guidance markdown is present" do
      let(:guidance_markdown) { "" }

      it "returns config for a medium default tag" do
        expect(question_base.question_text_size_and_tag).to eq({ size: "m" })
      end
    end

    context "when both the page heading and guidance markdown are nil" do
      let(:page_heading) { nil }
      let(:guidance_markdown) { nil }

      it "returns config for a large h1 tag" do
        expect(question_base.question_text_size_and_tag).to eq({ tag: "h1", size: "l" })
      end
    end

    context "when the page heading and guidance markdown are empty" do
      let(:page_heading) { "" }
      let(:guidance_markdown) { "" }

      it "returns config for a large h1 tag" do
        expect(question_base.question_text_size_and_tag).to eq({ tag: "h1", size: "l" })
      end
    end
  end
end
