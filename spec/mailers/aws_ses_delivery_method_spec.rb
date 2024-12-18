require "rails_helper"

RSpec.describe AwsSesDeliveryMethod do
  subject(:delivery) { described_class.new(settings: {}) }

  describe "#deliver!" do
    let(:mock_ses_client) { Aws::SESV2::Client.new(stub_responses: true) }
    let(:to) { ["email@example.com"] }

    let(:message) do
      instance_double(
        Mail::Message,
        to:,
      )
    end
    let(:message_content) { Faker::Lorem.word }
    let(:ses_message_id) { Faker::Alphanumeric.alphanumeric }
    let(:response) do
      instance_double(
        Aws::SESV2::Types::SendEmailResponse,
        message_id: ses_message_id,
      )
    end
    let(:configuration_set_name) { Faker::Lorem.word }

    before do
      allow(Aws::SESV2::Client).to receive(:new).and_return(mock_ses_client)
      allow(mock_ses_client).to receive(:send_email).and_return(response)
      allow(message).to receive(:to_s).and_return(message_content)
      allow(message).to receive(:message_id=)
      allow(Settings.aws).to receive(:ses_submission_email_configuration_set_name).and_return(configuration_set_name)

      delivery.deliver!(message)
    end

    it "calls AWS to send the email" do
      expect(mock_ses_client).to have_received(:send_email).with(
        {
          content: {
            raw: {
              data: message_content,
            },
          },
          configuration_set_name:,
        },
      )
    end

    it "sets the message ID to the message ID from SES" do
      expect(message).to have_received(:message_id=).with(ses_message_id)
    end
  end
end
