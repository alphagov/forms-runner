require "govuk_forms_markdown"

module GuidanceComponent
  class View < ViewComponent::Base
    attr_accessor :question

    def initialize(question)
      super()
      @question = question
    end

    def render?
      question.page_heading.present? && question.guidance_markdown.present?
    end

    def guidance_html
      HtmlMarkdownSanitizer.new.render_scrubbed_markdown(question.guidance_markdown)
    end
  end
end
