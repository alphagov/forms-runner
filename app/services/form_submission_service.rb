class FormSubmissionService
  class << self
    def call(**args)
      new(**args)
    end
  end

  def initialize(form:, reference:, preview_mode:)
    @form = form
    @reference = reference
    @preview_mode = preview_mode
  end

  def submit_form_to_processing_team
    raise StandardError, "Form id(#{@form.id}) has no steps i.e questions/answers to include in submission email" if @form.steps.blank?

    if !@preview_mode && @form.submission_email.blank?
      raise StandardError, "Form id(#{@form.id}) is missing a submission email address"
    end

    timestamp = submission_timestamp

    unless @form.submission_email.blank? && @preview_mode
      FormSubmissionMailer
        .email_completed_form(title: form_title,
                              text_input: email_body,
                              reference: @reference,
                              timestamp:,
                              submission_email: @form.submission_email).deliver_now
    end
  end

  class NotifyTemplateBodyFilter
    def build_question_answers_section(form)
      form.steps.map { |page|
        [prep_question_title(page.question_text),
         prep_answer_text(page.show_answer_in_email)].join
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

private

  def form_title
    return "TEST FORM: #{@form.form_name}" if @preview_mode

    @form.form_name
  end

  def email_body
    FormSubmissionService::NotifyTemplateBodyFilter.new.build_question_answers_section(@form)
  end

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end

  def submission_timestamp
    Time.use_zone(submission_timezone) { Time.zone.now }
  end
end
