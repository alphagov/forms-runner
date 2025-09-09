module Question
  class Base < ViewComponent::Base
    attr_accessor :form_builder, :question, :extra_question_text_suffix, :hint_id

    def initialize(form_builder:, question:, extra_question_text_suffix:)
      @form_builder = form_builder
      @question = question
      @extra_question_text_suffix = extra_question_text_suffix
      @hint_id = question.hint_text.present? ? "govuk-address-hint" : ""
      super()
    end

    def question_text_with_extra_suffix
      [CGI.escapeHTML(question.question_text_with_optional_suffix), extra_question_text_suffix].compact_blank.join(" ").html_safe
    end

    def hint_text
      return nil if question.hint_text.blank?

      tag.div(id: hint_id, class: "govuk-hint") do
        question.hint_text
      end
    end

    def question_text_size_and_tag
      return { tag: "h1", size: "l" } if question.page_heading.blank? && question.guidance_markdown.blank?

      { size: "m" }
    end
  end
end
