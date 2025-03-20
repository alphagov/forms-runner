class NotifyTemplateFormatter
  class FormattingError < StandardError; end

  def build_question_answers_section(completed_steps)
    completed_steps.map { |page|
      [prep_question_title(page),
       prep_answer_text(page)].join
    }.join("\n\n---\n\n").concat("\n")
  end

  def prep_question_title(page)
    "# #{page.question_text}\n"
  end

  def prep_answer_text(page)
    answer = page.show_answer_in_email

    return "\\[This question was skipped\\]" if answer.blank?

    escape(answer)
  rescue StandardError
    raise FormattingError, "could not format answer for question page #{page.id}"
  end

  def escape(text)
    text
      .then { normalize_whitespace _1 }
      .then { replace_setext_headings _1 }
      .then { escape_markdown_text _1 }
  end

  def escape_markdown_text(text)
    url_regex = URI::DEFAULT_PARSER.make_regexp(%w[http https])
    a = ""
    rest = text
    until rest.empty?
      head, match, rest = rest.partition(url_regex)
      a << escape_markdown_characters(head)
      a << match
    end
    a
  end

  def normalize_whitespace(text)
    text.strip.gsub(/\r\n?/, "\n").split(/\n\n+/).map(&:strip).join("\n\n")
  end

  def escape_markdown_characters(text)
    replaced = { "^" => "", "•" => "" }
    escaped = %w{! " # ' ` ( ) * + - . [ ] _ \{ | \} ~}.index_with { |c| "\\#{c}" }

    changes = replaced.merge(escaped)

    to_change = Regexp.union(changes.keys)
    text.gsub(to_change, changes)
  end

  def replace_setext_headings(text)
    # replace lengths of ^===$ with --- to stop them making headings
    text.gsub(/^(=+)$/) { "_" * Regexp.last_match(1).length }
  end
end
