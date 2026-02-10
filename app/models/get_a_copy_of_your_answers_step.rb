class GetACopyOfYourAnswersStep < Step
  GET_A_COPY_OF_YOUR_ANSWERS_PAGE_SLUG = "get-a-copy-of-your-answers".freeze

  attr_reader :next_page_slug, :page_slug, :page_id

  def initialize
    @page_id = GET_A_COPY_OF_YOUR_ANSWERS_PAGE_SLUG
    @next_page_slug = CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG
    @page_slug = GET_A_COPY_OF_YOUR_ANSWERS_PAGE_SLUG
    @question = Question::GetACopyOfYourAnswers.new

    super(page: nil, question: @question)
  end

  def end_page?
    false
  end

  def next_page_slug_after_routing
    @next_page_slug
  end

  def id
    GET_A_COPY_OF_YOUR_ANSWERS_PAGE_SLUG
  end
end
