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

  def prep_question_title_html(page)
    "<h2>#{page.question_text}</h2>"
  end

  def prep_answer_text_html(page)
    answer = page.show_answer_in_email

    return "<p>[This question was skipped]</p>" if answer.blank?

    "<p>#{sanitize(answer)}</p>"
  rescue StandardError
    raise FormattingError, "could not format answer for question page #{page.id}"
  end

  def prep_question_title_plain_text(page)
    "## #{page.question_text}"
  end

  def prep_answer_text_plain_text(page)
    answer = page.show_answer_in_email

    return "[This question was skipped]" if answer.blank?

    sanitize_plain_text(answer)
  end

  def sanitize(text)
    # TODO: we'll want to do more sanitizing on the answer text
    text
      .then { normalize_whitespace _1 }
  end

  def sanitize_plain_text(text)
    text
      .then { normalize_whitespace_plain_text _1 }
  end

  def normalize_whitespace(text)
    text.strip.gsub(/\r\n?/, "<br/>").split(/\n\n+/).map(&:strip).join("<br/><br/>")
  end

  def normalize_whitespace_plain_text(text)
    text.strip.gsub(/\r\n?/, "\n").split(/\n\n+/).map(&:strip).join("\n\n")
  end
end
