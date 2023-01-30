# frozen_string_literal: true

require "rails_helper"

describe "Settings" do
  settings = YAML.load_file(Rails.root.join("config/settings.yml")).with_indifferent_access
  expected_value_test = "expected_value_test"

  shared_examples expected_value_test do |key, source, expected_value|
    describe ".#{key}" do
      subject do
        source[key]
      end

      it "#{key} has a default value" do
        expect(subject).to eq(expected_value)
      end
    end
  end


  describe ".forms_api" do
    forms_api = settings[:forms_api]

    include_examples expected_value_test, :base_url, forms_api, "http://localhost:9292"
    include_examples expected_value_test, :auth_key, forms_api, "123456"
  end

  describe ".govuk_notify" do
    govuk_notify = settings[:govuk_notify]

    include_examples expected_value_test, :api_key, govuk_notify, "changeme"
    include_examples expected_value_test, :form_submission_email_reply_to_id, govuk_notify, "fab9373b-fb7c-483f-ae25-5a9852bfcc04"
    include_examples expected_value_test, :form_submission_email_template_id, govuk_notify, "427eb8bc-ce0d-40a3-bf54-d76e8c3ec916"
  end
end
