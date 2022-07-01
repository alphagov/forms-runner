require_relative "../../app/models/step"
require_relative "../../app/lib/question_register"

class StepFactory
  class PageNotFoundError < StandardError
    def initialize(msg = "My default message")
      super
    end
  end

  attr_accessor :submission_email, :form_id

  def initialize(form:)
    @form = form
    @pages = form.pages

    @submission_email = form.submission_email
    @form_id = form.id
  end

  def create_step(page_slug_or_start)
    # Raise notfound if there is no page?

    page_slug = page_slug_or_start.to_s == "_start" ? @form.start_page : page_slug_or_start

    page_slug = page_slug.to_s
    # for now, we use the page id as slug
    page = @pages.find { |p| p.id.to_s == page_slug }
    raise PageNotFoundError, "Can't find page #{page_slug}" if page.nil?

    question = QuestionRegister.from_page(page).new
    question.question_text = page.question_text
    question.question_short_name = page.question_short_name
    question.hint_text = page.respond_to?(:hint_text) ? page.hint_text : nil
    next_page_slug = page.has_next? ? page.next.to_s : nil
    is_start_page = page.id.to_s == start_step_id

    Step.new(question:, page_id: page.id, form_id: @form.id, next_page_slug:, is_start_page:, page_slug:)
  end

  def start_step
    create_step("_start")
  end

  def start_step_id
    @form.start_page.to_s
  end
end
