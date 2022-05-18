require "notifications/client"

class NotifyService
  def initialize
    @notify_api_key = ENV["NOTIFY_API_KEY"]
  end

  def send_email(email_address, title, text_input, submission_time)
    unless @notify_api_key
      Rails.logger.warn "Warning: no NOTIFY_API_KEY set."
      return nil
    end

    client = Notifications::Client.new(@notify_api_key)
    client.send_email(
      email_address: email_address,
      template_id: "c10a4cea-b937-4f9e-be6f-f18583e55806",
      personalisation: {
        title: title,
        text_input: text_input,
        submission_time: submission_time,
      },
    )
  end
end
