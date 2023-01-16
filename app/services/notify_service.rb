require "notifications/client"

class NotifyService
  def initialize
    @notify_api_key = Settings.govuk_notify.api_key
  end

  def send_email(form, reference, preview_mode: false)
    email_address = form.submission_email
    title = form.form_name
    text_input = build_question_answers_section(form)
    @preview_mode = preview_mode
    unless @notify_api_key
      Rails.logger.warn "Warning: no NOTIFY_API_KEY set."
      return nil
    end

    client = Notifications::Client.new(@notify_api_key)

    client.send_email(**email(email_address, title, text_input, reference))
  end

  def email(email_address, title, text_input, reference)
    title = "TEST FORM: #{title}" if @preview_mode
    timestamp = submission_timestamp
    {
      email_address:,
      template_id: Settings.govuk_notify.form_submission_email_template_id,
      personalisation: {
        title:,
        text_input:,
        submission_time: timestamp.strftime("%H:%M:%S"),
        submission_date: timestamp.strftime("%-d %B %Y"),
      },
      reference:,
    }
  end

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end

  def submission_timestamp
    Time.use_zone(submission_timezone) { Time.zone.now }
  end

  def build_question_answers_section(form)
    form.steps.map { |page|
      [prep_question_title(page.question_text),
       prep_answer_text(page.show_answer)].join
    }.join("\n\n---\n\n").concat("\n")
  end

  def prep_question_title(question_text)
    "# #{question_text}\n"
  end

  def prep_answer_text(answer)
    return "\\[This question was skipped\\]" if answer.blank?

    escape(answer)
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
