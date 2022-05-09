require 'notifications/client'

class NotifyService
  def initialize
    @notify_api_key = ENV['NOTIFY_API_KEY']
  end

  def send_email(email_address, title, text_input, submission_time)
    unless @notify_api_key
      Rails.logger.warn 'Warning: no NOTIFY_API_KEY set.'
      return nil
    end

    client = Notifications::Client.new(@notify_api_key)
    client.send_email(
          email_address: email_address,
        template_id: 'template id tbd',
        personalisation: {
          title: title,
          text_input: text_input,
          submission_time: submission_time
        }
    )
  end
end
