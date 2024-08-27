require "aws-sdk-sesv2"

class AwsSESDeliveryMethod
  attr_accessor :settings

  def initialize(settings)
    self.settings = settings
  end

  def deliver!(message)
    ses = Aws::SESV2::Client.new(region: "eu-west-2")
    response = ses.send_email({
      content: {
        raw: {
          data: message.to_s,
        },
      },
      configuration_set_name: "bounces_and_complaints_handling_rule",
    })
    # Overwrite the generated message_id with the id returned by SES.
    message.message_id = response.message_id
  end
end
