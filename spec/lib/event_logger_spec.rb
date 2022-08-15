require "rails_helper"
require_relative "../../app/lib/event_logger"

RSpec.describe EventLogger do
  it "logs an event" do
    allow(Rails.logger).to receive(:info).at_least(:once)

    described_class.log("page_submission", { test: true })

    expect(Rails.logger).to have_received(:info).with("[page_submission] {\"test\":true}")
  end
end
