module Question
  class Base < ApplicationComponent
    attr_accessor :form_builder, :question, :mode, :hint_id

    def initialize(form_builder:, question:, mode:)
      @form_builder = form_builder
      @question = question
      @mode = mode
      @hint_id = question.hint_text.present? ? "govuk-address-hint" : ""
      super()
    end

    def question_text_with_extra_suffix
      helpers.question_text_with_hidden_mode(question.question_text_with_optional_suffix, mode)
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
