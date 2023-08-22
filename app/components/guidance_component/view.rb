require "govuk_forms_markdown"

module GuidanceComponent
  class View < ViewComponent::Base
    attr_accessor :question

    def initialize(question)
      super
      @question = question
    end

    def render?
      question.page_heading.present? && question.guidance_markdown.present?
    end

    def guidance_html
      ActionController::Base.helpers.sanitize(GovukFormsMarkdown.render(question.guidance_markdown), scrubber: MarkdownScrubber.new)
    end
  end
end
