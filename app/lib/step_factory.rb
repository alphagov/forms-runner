class StepFactory
  START_PAGE = "_start".freeze
  CHECK_YOUR_ANSWERS_PAGE = "check_your_answers".freeze
  PAGE_SLUG_REGEX = /\d+|check_your_answers/

  class PageNotFoundError < StandardError
    def initialize(msg = "Page not found.")
      super
    end
  end

  attr_accessor :submission_email, :form_id

  def initialize(form:)
    @form = form
    @pages = form.pages

    @submission_email = form.submission_email
    @form_id = form.id
    @form_slug = form.form_slug
  end

  def create_step(page_slug_or_start)
    # Normalize the id or constant passed in
    page_slug = page_slug_or_start.to_s == START_PAGE ? @form.start_page : page_slug_or_start
    page_slug = page_slug.to_s

    return CheckYourAnswersStep.new(form_id: @form_id) if page_slug == CHECK_YOUR_ANSWERS_PAGE

    # for now, we use the page id as slug
    page = @pages.find { |p| p.id.to_s == page_slug }
    raise PageNotFoundError, "Can't find page #{page_slug}" if page.nil?

    next_page_slug = page.has_next_page? ? page.next_page.to_s : CHECK_YOUR_ANSWERS_PAGE
    question = QuestionRegister.from_page(page)

    Step.new(question:, page_id: page.id, form_id: @form_id, form_slug: @form_slug, next_page_slug:, page_slug:, page_number: page.number(@form))
  end

  def start_step
    create_step(START_PAGE)
  end
end
