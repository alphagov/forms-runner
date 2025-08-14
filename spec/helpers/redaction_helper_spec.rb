require "rails_helper"

RSpec.describe RedactionHelper, type: :helper do
  context "when condition" do
    it "redacts all emails in the string, keeping special characters and characters following special characters" do
      expect(helper.redact_emails_from_sentry_message("some text an_email$123@example.com and another^email@example.com"))
        .to eq "some text a*_e****$1**(at)e******.c** and a******^e****(at)e******.c**"
    end
  end
end
