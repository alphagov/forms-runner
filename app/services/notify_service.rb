require "notifications/client"

class NotifyService
  def initialize
    @notify_api_key = ENV["NOTIFY_API_KEY"]
  end

  def send_email(form, preview_mode: false)
    email_address = form.submission_email
    title = form.form_name
    text_input = form.steps.map { |page| "# #{safe_markdown(page.question_text)}\n#{safe_markdown(page.show_answer)}" }.join("\n\n---\n\n")
    @preview_mode = preview_mode
    unless @notify_api_key
      Rails.logger.warn "Warning: no NOTIFY_API_KEY set."
      return nil
    end

    client = Notifications::Client.new(@notify_api_key)
    client.send_email(**email(email_address, title, text_input))
  end

  def email(email_address, title, text_input)
    title = "TEST FORM: #{title}" if @preview_mode
    timestamp = submission_timestamp
    {
      email_address:,
      template_id: "427eb8bc-ce0d-40a3-bf54-d76e8c3ec916",
      personalisation: {
        title:,
        text_input:,
        submission_time: timestamp.strftime("%H:%M:%S"),
        submission_date: timestamp.strftime("%-d %B %Y"),
      },
    }
  end

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end

  def submission_timestamp
    Time.use_zone(submission_timezone) { Time.zone.now }
  end

  def safe_markdown(text)
    escaped = %w{! # ( ) * [ \\ ] _ ` | ~ - .}.index_with { |c| "\\#{c}" }
    to_escape = Regexp.union(escaped.keys)

    text.gsub(to_escape, escaped)
  end
end
