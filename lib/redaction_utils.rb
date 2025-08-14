module RedactionUtils
  def redact_emails_from_sentry_message(input)
    input.gsub(/\S+@\S+/) do |match|
      # Redact all alphanumeric characters not directly after a non-alphanumeric character.
      # The idea is so we can identify if any special characters or escape sequences are causing the issue with
      # ActionMailer parsing emails.
      # Also replace the @ with (at) so that Sentry doesn't completely strip out the email
      match.gsub(/(?<=[A-Za-z0-9])([A-Za-z0-9])/, "*")
           .gsub(/@/, "(at)")
    end
  end
end
