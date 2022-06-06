require 'rails_helper'

RSpec.describe HostingEnvironment do
  it "sandbox mode returns true" do
    ClimateControl.modify SANDBOX: "true" do
      expect(described_class.sandbox_mode?).to be(true)
    end
  end
end
