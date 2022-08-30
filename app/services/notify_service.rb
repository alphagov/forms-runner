require "notifications/client"

class NotifyService
  def initialize
    @notify_api_key = ENV["NOTIFY_API_KEY"]
  end

  def send_email(email_address, title, text_input)
    unless @notify_api_key
      Rails.logger.warn "Warning: no NOTIFY_API_KEY set."
      return nil
    end

    timestamp = Time.now.zone
    submission_time = timestamp.strftime("%H:%M:%S")
    submission_date = timestamp.strftime("%-d %B %Y")

    client = Notifications::Client.new(@notify_api_key)
    client.send_email(
      email_address:,
      template_id: "427eb8bc-ce0d-40a3-bf54-d76e8c3ec916",
      personalisation: {
        title:,
        text_input:,
        submission_time:,
        submission_date:,
      },
    )
  end
end
