class SesEmailFormatter
  H_RULE = '<hr style="border: 0; height: 1px; background: #B1B4B6; Margin: 30px 0 30px 0;">'.freeze
  H_RULE_PLAIN_TEXT = "\n\n---\n\n".freeze

  class FormattingError < StandardError; end

  def build_question_answers_section_html(completed_steps)
    completed_steps.map { |step|
      [prep_question_title_html(step),
       prep_answer_text_html(step)].join
    }.join(H_RULE)
  end

  def build_question_answers_section_plain_text(completed_steps)
    completed_steps.map { |step|
      [prep_question_title_plain_text(step),
       prep_answer_text_plain_text(step)].join("\n\n")
    }.join(H_RULE_PLAIN_TEXT)
  end

private

  def prep_question_title_html(step)
    "<h3>#{prep_question_title_plain_text(step)}</h3>"
  end

  def prep_answer_text_html(step)
    "<p>#{convert_newlines_to_html(prep_answer_text_plain_text(step))}</p>"
  rescue StandardError
    raise FormattingError, "could not format answer for question page #{step.id}"
  end

  def prep_question_title_plain_text(step)
    step.question.question_text
  end

  def prep_answer_text_plain_text(step)
    answer = step.show_answer_in_email

    return "[#{I18n.t('mailer.submission.question_skipped')}]" if answer.blank?

    sanitize(answer)
  rescue StandardError
    raise FormattingError, "could not format answer for question page #{step.id}"
  end

  def sanitize(text)
    text
      .then { normalize_whitespace _1 }
  end

  def normalize_whitespace(text)
    text.strip.gsub(/\r\n?/, "\n").split(/\n\n+/).map(&:strip).join("\n\n")
  end

  def convert_newlines_to_html(text)
    text.gsub("\n", "<br/>")
  end
end
