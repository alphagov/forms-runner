module GovukNotifyRails
  class TestMailer < Mail::TestMailer
    @govuk_notify_responses = []

    class << self
      attr_reader :govuk_notify_responses
    end

    def deliver!(mail)
      super

      mail.govuk_notify_response =
        GovukNotifyRails::TestMailer.govuk_notify_responses.pop \
        || Notifications::Client::ResponseNotification.new({})
    end
  end
end
