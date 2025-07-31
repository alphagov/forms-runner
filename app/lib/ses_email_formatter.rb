class SesEmailFormatter
  H_RULE = '<hr style="border: 0; height: 1px; background: #B1B4B6; Margin: 30px 0 30px 0;">'.freeze
  H_RULE_PLAIN_TEXT = "\n\n---\n\n".freeze

  class FormattingError < StandardError; end

  def build_question_answers_section_html(completed_steps)
    completed_steps.map { |page|
      [prep_question_title_html(page),
       prep_answer_text_html(page)].join
    }.join(H_RULE)
  end

  def build_question_answers_section_plain_text(completed_steps)
    completed_steps.map { |page|
      [prep_question_title_plain_text(page),
       prep_answer_text_plain_text(page)].join("\n\n")
    }.join(H_RULE_PLAIN_TEXT)
  end

private

  def prep_question_title_html(page)
    "<h2>#{prep_question_title_plain_text(page)}</h2>"
  end

  def prep_answer_text_html(page)
    "<p>#{convert_newlines_to_html(prep_answer_text_plain_text(page))}</p>"
  rescue StandardError
    raise FormattingError, "could not format answer for question page #{page.id}"
  end

  def prep_question_title_plain_text(page)
    page.question_text
  end

  def prep_answer_text_plain_text(page)
    answer = page.show_answer_in_email

    return "[#{I18n.t('mailer.submission.question_skipped')}]" if answer.blank?

    sanitize(answer)
  rescue StandardError
    raise FormattingError, "could not format answer for question page #{page.id}"
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
