require 'notifications/client'
client = Notifications::Client.new(ENV["NOTIFY_API_KEY"])

class NotifyService
    def initialize
      @notify_api_key = ENV['NOTIFY_API_KEY']
    end
  
    def test_email(email_address)
        unless @notify_api_key
          Rails.logger.warn 'Warning: no NOTIFY_API_KEY set.'
          return nil
        end
    
        client = Notifications::Client.new(@notify_api_key)
        client.send_email(
            email_address: email_address,
            template_id: "f33517ff-2a88-4f6e-b855-c550268ce08a",
            personalisation: {
            }
        )
    end
end

notify_service = NotifyService.new
notify_service.test_email("email@email.com)