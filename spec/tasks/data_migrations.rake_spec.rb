require "rake"
require "rails_helper"

RSpec.describe "data_migrations.rake" do
  before do
    Rake.application.rake_require "tasks/data_migrations"
    Rake::Task.define_task(:environment)
  end

  describe "data_migrations:create_deliveries" do
    subject(:task) do
      Rake::Task["data_migrations:create_deliveries"]
        .tap(&:reenable)
    end

    let!(:submission) { create(:submission, :sent, delivered_at:) }
    let(:delivered_at) { Time.zone.now - 10.minutes }
    let!(:bounced_submission) { create(:submission, :bounced, bounced_at:) }
    let(:bounced_at) { Time.zone.now - 5.minutes }
    let(:submission_with_delivery) do
      create(:submission).tap do |submission|
        submission.deliveries.create!(delivery_reference: "EXISTING")
      end
    end

    it "creates a delivery for an existing submission without a delivery" do
      expect {
        task.invoke
      }.to change { submission.deliveries.count }.by(1)

      expect(submission.deliveries.first).to have_attributes(
        created_at: submission.created_at,
        delivery_reference: submission.mail_message_id,
        delivered_at: submission.delivered_at,
        last_attempt_at: submission.last_delivery_attempt,
        failed_at: nil,
        failure_reason: nil,
      )
    end

    it "create a delivery for a bounced submission without a delivery" do
      expect {
        task.invoke
      }.to change { bounced_submission.deliveries.count }.by(1)

      expect(bounced_submission.deliveries.first).to have_attributes(
        created_at: bounced_submission.created_at,
        delivery_reference: bounced_submission.mail_message_id,
        delivered_at: bounced_submission.delivered_at,
        last_attempt_at: bounced_submission.last_delivery_attempt,
        failed_at: bounced_submission.bounced_at,
        failure_reason: "bounced",
      )
    end

    it "does not create a delivery for a submission that already has one" do
      expect {
        task.invoke
      }.not_to(change { submission_with_delivery.deliveries.count })
    end
  end
end
