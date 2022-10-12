require "rails_helper"

RSpec.describe NotifyService do
  let(:notify_api_key) { nil }

  around do |example|
    ClimateControl.modify NOTIFY_API_KEY: notify_api_key do
      example.run
    end
  end

  context "with api key set" do
    let(:notify_api_key) { "test-key" }

    context "with a time in BST" do
      let(:submission_datetime) { Time.utc(2022, 9, 14, 10, 0o0, 0o0) }

      it "sends correct values to notify" do
        fake_notify_client = instance_double(Notifications::Client)
        allow(fake_notify_client).to receive(:send_email)
        allow(Notifications::Client).to receive(:new).and_return(fake_notify_client)

        travel_to submission_datetime do
          notify_service = described_class.new
          form = OpenStruct.new(submission_email:"fake-email", form_name: "title", steps: [OpenStruct.new(question_text: "text", show_answer: "Testing")])
          notify_service.send_email(form)
          expect(fake_notify_client).to have_received(:send_email).with(
            { email_address: "fake-email",
              personalisation: {
                submission_date: "14 September 2022",
                submission_time: "11:00:00",
                text_input: "# text\nTesting",
                title: "title",
              },
              template_id: "427eb8bc-ce0d-40a3-bf54-d76e8c3ec916" },
          ).once
        end
      end
    end

    context "with a time in GMT" do
      let(:submission_datetime) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }

      it "sends correct values to notify" do
        fake_notify_client = instance_double(Notifications::Client)
        allow(fake_notify_client).to receive(:send_email)
        allow(Notifications::Client).to receive(:new).and_return(fake_notify_client)

        travel_to submission_datetime do
          notify_service = described_class.new
          form = OpenStruct.new(submission_email:"fake-email", form_name: "title", steps: [OpenStruct.new(question_text: "text", show_answer: "Testing")])
          notify_service.send_email(form)
          expect(fake_notify_client).to have_received(:send_email).with(
            { email_address: "fake-email",
              personalisation: {
                submission_date: "14 December 2022",
                submission_time: "10:00:00",
                text_input: "# text\nTesting",
                title: "title",
              },
              template_id: "427eb8bc-ce0d-40a3-bf54-d76e8c3ec916" },
          ).once
        end
      end
    end

    context "with an email subject identifying that it was submitted from preview-form" do
      let(:submission_datetime) { Time.utc(2022, 12, 14, 10, 00, 00) }
      it "sends correct values to notify" do
        fake_notify_client = instance_double(Notifications::Client)
        allow(fake_notify_client).to receive(:send_email)
        allow(Notifications::Client).to receive(:new).and_return(fake_notify_client)

        travel_to submission_datetime do
          notify_service = NotifyService.new
          form = OpenStruct.new(submission_email:"fake-email", form_name: "title", steps: [OpenStruct.new(question_text: "text", show_answer: "Testing")])
          notify_service.send_email(form,preview_mode: true)
          expect(fake_notify_client).to have_received(:send_email).with(
            {:email_address=>'fake-email',
             :personalisation=>{
               :submission_date=>"14 December 2022",
               :submission_time=>"10:00:00",
               :text_input=>"# text\nTesting",
               :title=>'TEST FORM: title'
             },
             :template_id=>"427eb8bc-ce0d-40a3-bf54-d76e8c3ec916"}).once
        end
      end
    end
  end

  context "with no api key set" do
    it "does not send an email through notify" do
      fake_notify_client = instance_double(Notifications::Client)
      allow(fake_notify_client).to receive(:send_email)
      allow(Notifications::Client).to receive(:new).and_return(fake_notify_client)
      expect(Rails.logger).to receive(:warn).with(/NOTIFY_API_KEY/)

      notify_service = described_class.new
      form = OpenStruct.new(submission_email:"fake-email", form_name: "title", steps: [OpenStruct.new(question_text: "text", show_answer: "Testing")])
      notify_service.send_email(form)
      expect(fake_notify_client).not_to have_received(:send_email)
    end
  end

  describe "#safe_markdown" do
    it "returns passed in values" do
      expect(described_class.new.safe_markdown("Testing")).to eq "Testing"
    end

    it "escapes markdown syntax" do
      expect(described_class.new.safe_markdown("1.5")).to eq "1\\.5"
    end
  end
end
