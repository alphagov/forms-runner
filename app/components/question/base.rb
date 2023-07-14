module Question
  class Base < ViewComponent::Base
    attr_accessor :form_builder, :question, :extra_question_text_suffix

    def initialize(form_builder:, question:, extra_question_text_suffix:)
      @form_builder = form_builder
      @question = question
      @extra_question_text_suffix = extra_question_text_suffix
      super
    end

    def question_text_with_extra_suffix
      [CGI.escapeHTML(question.question_text), extra_question_text_suffix].compact_blank.join(" ").html_safe
    end
  end
end
