module GovukNotifyRailsHelpers
  def allow_mailer_to_return_mail_with_govuk_notify_response_with(mailer, method_name, **response_notification_stubs)
    allow(mailer).to receive(method_name).and_wrap_original do |original_method, *args, **kwargs|
      GovukNotifyRails::TestMailer.govuk_notify_responses <<
        instance_double(Notifications::Client::ResponseNotification, response_notification_stubs)

      original_method.call(*args, **kwargs)
    end
  end
end

RSpec.configure do |config|
  config.include GovukNotifyRailsHelpers
end
