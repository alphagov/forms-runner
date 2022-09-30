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
end
