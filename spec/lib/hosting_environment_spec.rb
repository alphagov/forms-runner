require "rails_helper"

RSpec.describe HostingEnvironment do
  describe ".test_environment?" do
    let(:paas_environment) { nil }
    let(:rails_env) { nil }

    around do |example|
      ClimateControl.modify PAAS_ENVIRONMENT: paas_environment do
        example.run
      end
    end

    context "with PAAS_ENVIRONMENT set to dev" do
      let(:paas_environment) { "dev" }

      it "returns true" do
        expect(described_class.test_environment?).to be(true)
      end
    end

    context "with PAAS_ENVIRONMENT set to production" do
      let(:paas_environment) { "production" }

      it "returns true" do
        expect(described_class.test_environment?).to be(false)
      end
    end

    context "when in local development" do
      it "returns true" do
        allow(Rails).to receive(:env).and_return(OpenStruct.new(production?: false))
        expect(described_class.test_environment?).to be(true)
      end
    end

    context "when in production" do
      it "returns false" do
        allow(Rails).to receive(:env).and_return(OpenStruct.new(production?: true))
        expect(described_class.test_environment?).to be(false)
      end
    end
  end
end
