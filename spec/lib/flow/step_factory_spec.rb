require "rails_helper"

RSpec.describe Flow::StepFactory do
  let(:form) { build :form, id: "form-123", form_slug: "test-form", start_page: "page-1", pages: [] }
  let(:factory) { described_class.new(form:) }

  describe "#create_step" do
    context "when creating a CheckYourAnswersStep" do
      it "returns a CheckYourAnswersStep instance" do
        step = factory.create_step(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
        expect(step).to be_a(CheckYourAnswersStep)
        expect(step.form_id).to eq("form-123")
      end
    end

    context "when creating a regular step" do
      let(:page) { build_stubbed :page, id: "page-1", has_next_page?: true, next_page: "page-2" }
      let(:question) { instance_double(Question) }

      before do
        allow(form.pages).to receive(:find).and_return(page)
        allow(Flow::QuestionRegister).to receive(:from_page).with(page).and_return(question)
      end

      it "returns a Step instance" do
        step = factory.create_step("page-1")
        expect(step).to be_a(Step)
        expect(step.question).to eq(question)
        expect(step.form_id).to eq("form-123")
        expect(step.form_slug).to eq("test-form")
        expect(step.next_page_slug).to eq("page-2")
        expect(step.page_slug).to eq("page-1")
      end

      context "when it is the last page" do
        let(:page) { build :page, id: "page-1", has_next_page?: false }

        it "sets next_page_slug to CHECK_YOUR_ANSWERS_PAGE_SLUG" do
          step = factory.create_step("page-1")
          expect(step.next_page_slug).to eq(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
        end
      end
    end

    context "when creating a repeating step" do
      let(:page) { build :page, :with_repeatable, page_slug: "page-1" }
      let(:question) { instance_double(Question) }

      before do
        allow(form.pages).to receive(:find).and_return(page)
        allow(Flow::QuestionRegister).to receive(:from_page).with(page).and_return(question)
      end

      it "a RepeatingStep is created" do
        step = factory.create_step(page.page_slug)
        expect(step).to be_a(RepeatableStep)
      end
    end

    context "when page is not found" do
      it "raises a PageNotFoundError" do
        expect { factory.create_step("non-existent-page") }.to raise_error(Flow::StepFactory::PageNotFoundError)
      end
    end

    context "when creating the start step" do
      let(:start_page) { build :page, id: "page-1", has_next_page?: true, next_page: "page-2" }

      before do
        allow(form.pages).to receive(:find).and_return(start_page)
        allow(Flow::QuestionRegister).to receive(:from_page).with(start_page).and_return(instance_double(Question))
      end

      it "creates a step for the start page" do
        step = factory.create_step(Flow::StepFactory::START_PAGE)
        expect(step).to be_a(Step)
        expect(step.page_slug).to eq("page-1")
      end
    end
  end

  describe "#start_step" do
    it "calls create_step with START_PAGE" do
      expect(factory).to receive(:create_step).with(Flow::StepFactory::START_PAGE)
      factory.start_step
    end
  end

  describe Flow::StepFactory::PAGE_SLUG_REGEX do
    it "matches valid page_id values" do
      %w[1 123 0123456789 check-your-answers].each do |string|
        expect(described_class).to match string
      end
    end

    it "does not match invalid page_id values" do
      %w[no ten inspect_your_answers /secret/login.php].each do |string|
        expect(described_class).not_to match string
      end
    end
  end
end
