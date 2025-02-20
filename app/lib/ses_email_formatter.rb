class SesEmailFormatter
  H_RULE = '<hr style="border: 0; height: 1px; background: #B1B4B6; Margin: 30px 0 30px 0;">'.freeze

  def build_question_answers_section(completed_steps)
    completed_steps.map { |page|
      [prep_question_title(page.question_text),
       prep_answer_text(page.show_answer_in_email)].join
    }.join(H_RULE)
  end

  def prep_question_title(question_text)
    "<h2>#{question_text}</h2>"
  end

  def prep_answer_text(answer)
    return "<p>[This question was skipped]</p>" if answer.blank?

    "<p>#{sanitize(answer)}</p>"
  end

  def sanitize(text)
    # TODO: we'll want to do more sanitizing on the answer text
    text
      .then { normalize_whitespace _1 }
  end

  def normalize_whitespace(text)
    text.strip.gsub(/\r\n?/, "<br/>").split(/\n\n+/).map(&:strip).join("<br/><br/>")
  end
end
