module CheckYourAnswersComponent
  class View < ApplicationComponent
    def initialize(form:, steps:, mode:)
      @form = form
      @steps = steps
      @mode = mode
      super()
    end

    def rows
      @rows ||= @steps.flat_map { |step| step_to_row(step) }
    end

    def full_width?
      @steps.any? { |step| step.question.has_long_answer? }
    end

  private

    def step_to_row(step)
      question_name = step.question.question_text_for_check_your_answers
      {
        key: { text: helpers.sanitize(question_name) },
        value: { text: answer_text(step.show_answer) },
        actions: [{ text: I18n.t("govuk_components.govuk_summary_list.change"), href: change_link(step), visually_hidden_text: helpers.strip_tags(question_name) }],
      }
    end

    def answer_text(answer)
      HtmlMarkdownSanitizer.new.format_paragraphs(answer.presence || I18n.t("form.check_your_answers.not_completed"))
    end

    def change_link(step)
      if step.repeatable? && step.show_answer.present?
        change_add_another_answer_path(mode: @mode, form_id: @form.id, form_slug: @form.form_slug, page_slug: step.id)
      else
        form_change_answer_path(mode: @mode, form_id: @form.id, form_slug: @form.form_slug, page_slug: step.id)
      end
    end
  end
end
