# rubocop:disable Style/ClassVars

module ActionControllerNotificationsHelpers
  @@payloads = []
  @@process_action_subscriber = nil

  def logging_context
    payload[:custom_payload]
  end

  def payloads
    @@payloads ||= []
  end

  def payload
    payloads.last
  end

  def process_action_subscriber
    @@process_action_subscriber ||= ActiveSupport::Notifications.subscribe("process_action.action_controller") do |_, _, _, _, payload|
      payloads << payload
    end
  end

  def reset_action_controller_notifications
    payloads.clear
  end

  def subscribe_to_action_controller_notifications
    process_action_subscriber
  end
end

# rubocop:enable Style/ClassVars

RSpec.configure do |config|
  config.include ActionControllerNotificationsHelpers, type: :request

  config.before(:example, type: :request) do
    subscribe_to_action_controller_notifications
  end

  config.after(:example, type: :request) do
    reset_action_controller_notifications
  end
end
