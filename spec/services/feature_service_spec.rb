require "rails_helper"

describe FeatureService do
  describe "#enabled?" do
    subject :feature_service do
      described_class
    end

    let(:form) { build :form, id: 123 }

    context "when the feature key has a boolean value" do
      context "when feature key has value true" do
        before do
          Settings.features[:some_feature] = true
        end

        it "is enabled" do
          expect(feature_service).to be_enabled(:some_feature, form)
        end
      end

      context "when feature key has value false" do
        before do
          Settings.features[:some_feature] = false
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end
      end

      context "when empty features" do
        before do
          allow(Settings).to receive(:features).and_return(nil)
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end
      end

      context "when nested features" do
        before do
          Settings.features[:some] = OpenStruct.new(nested_feature: true)
        end

        it "is enabled" do
          expect(feature_service).to be_enabled("some.nested_feature")
        end
      end
    end

    context "when the feature key has an object value" do
      context "when the enabled key exists and is set to true" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: true)
        end

        it "is enabled" do
          expect(feature_service).to be_enabled(:some_feature, form)
        end
      end

      context "when the enabled key exists and is set to false" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false)
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end
      end

      context "when the enabled key does not exist" do
        before do
          Settings.features[:some_feature] = Config::Options.new
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end
      end

      context "when a key exists for the form overriding the feature to be enabled" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false, forms: { "123": true })
        end

        it "is enabled" do
          expect(feature_service).to be_enabled(:some_feature, form)
        end
      end

      context "when a key exists for the form overriding the feature to be disabled" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: true, forms: { "123": false })
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end
      end

      context "when a key exists for the form overriding the feature and the form has not been provided to the service" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false, forms: { "123": true })
        end

        it "raises an error" do
          expect { feature_service.enabled?(:some_feature) }.to raise_error described_class::FormRequiredError
        end
      end

      context "when a key exists for a different form" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false, forms: { "another_form": true })
        end

        it "returns the value of the enabled flag" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end
      end

      context "when the forms object is empty" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: true, forms: {})
        end

        it "returns the value of the enabled flag" do
          expect(feature_service).to be_enabled(:some_feature, form)
        end
      end

      context "when the form does not have a form id set" do
        before do
          form.id = nil
          Settings.features[:some_feature] = Config::Options.new(enabled: false, forms: { "123": true })
        end

        it "returns the value of the enabled flag" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end
      end
    end
  end
end
