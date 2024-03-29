ActionMailer::Base.add_delivery_method :govuk_notify, GovukNotifyRails::Delivery, api_key: Settings.govuk_notify.api_key

if Rails.env.test?
  require "govuk_notify_rails/test_mailer"
  ActionMailer::Base.add_delivery_method :govuk_notify_test, GovukNotifyRails::TestMailer if Rails.env.test?
end
