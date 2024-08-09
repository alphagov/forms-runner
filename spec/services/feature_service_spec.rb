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

        context "and the feature is enabled for a specific form" do
          before do
            Settings.features[:some_feature] = Config::Options.new(enabled: true, enabled_for_form_ids: "123")
          end

          it "is enabled for the specific form" do
            expect(feature_service).to be_enabled(:some_feature, form)
          end

          it "is enabled for other forms" do
            other_form = build :form, id: 1234

            expect(feature_service).to be_enabled(:some_feature, other_form)
          end
        end
      end

      context "when the enabled key exists and is set to false" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: false)
        end

        it "is not enabled" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end

        context "and the feature is enabled for this specific form" do
          before do
            Settings.features[:some_feature] = Config::Options.new(enabled: false, enabled_for_form_ids: 123)
          end

          it "is enabled" do
            expect(feature_service).to be_enabled(:some_feature, form)
          end

          context "but the form has not been provided to the service" do
            it "raises an error" do
              expect { feature_service.enabled?(:some_feature) }.to raise_error described_class::FormRequiredError
            end
          end
        end

        context "and the feature is enabled for a different form" do
          before do
            Settings.features[:some_feature] = Config::Options.new(enabled: false, enabled_for_form_ids: 122)
          end

          it "returns the value of the enabled flag" do
            expect(feature_service).not_to be_enabled(:some_feature, form)
          end
        end

        context "and the feature is enabled for multiple forms" do
          before do
            Settings.features[:some_feature] = Config::Options.new(enabled: false, enabled_for_form_ids: "122, 123")
          end

          it "returns the value of the enabled flag" do
            other_form = build :form, id: 122

            expect(feature_service).to be_enabled(:some_feature, other_form)
            expect(feature_service).to be_enabled(:some_feature, form)
          end
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

      context "when the enabled_for_form_ids array is empty" do
        before do
          Settings.features[:some_feature] = Config::Options.new(enabled: true, enabled_for_form_ids: "")
        end

        it "returns the value of the enabled flag" do
          expect(feature_service).to be_enabled(:some_feature, form)
        end
      end

      context "when the form does not have a form id set" do
        before do
          form.id = nil
          Settings.features[:some_feature] = Config::Options.new(enabled: false, enabled_for_form_ids: "123")
        end

        it "returns the value of the enabled flag" do
          expect(feature_service).not_to be_enabled(:some_feature, form)
        end
      end
    end
  end
end
