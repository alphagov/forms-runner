require "rails_helper"

RSpec.describe ScheduleDailyBatchDeliveriesJob do
  include ActiveSupport::Testing::TimeHelpers
  include ActiveJob::TestHelper

  let(:travel_time) { Time.zone.local(2022, 12, 2) }
  let(:form_id) { 101 }
  let(:other_form_id) { 201 }
  let(:form_submissions) { create_list(:submission, 2, form_id: form_id, mode: "form") }
  let(:other_form_submissions) { create_list(:submission, 1, form_id: other_form_id, mode: "preview-draft") }
  let!(:batches) do
    [
      DailySubmissionBatchSelector::Batch.new(101, "form", form_submissions),
      DailySubmissionBatchSelector::Batch.new(201, "preview-draft", other_form_submissions),
    ]
  end

  around do |example|
    travel_to travel_time do
      example.run
    end
  end

  before do
    allow(DailySubmissionBatchSelector).to receive(:batches).and_return(batches.to_enum)
    described_class.perform_now
  end

  it "calls the selector with yesterday's date" do
    expect(DailySubmissionBatchSelector).to have_received(:batches).with(Time.zone.yesterday)
  end

  it "creates a delivery record per batch job" do
    expect(Delivery.daily.count).to eq(2)
    expect(Delivery.first.submissions.map(&:id)).to match_array(form_submissions.map(&:id))
    expect(Delivery.second.submissions.map(&:id)).to match_array(other_form_submissions.map(&:id))
  end

  it "enqueues a SendSubmissionBatchJob per batch" do
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(2)
  end

  it "enqueues the jobs with the correct args" do
    enqueued_args = ActiveJob::Base.queue_adapter.enqueued_jobs.map { |j| j[:args].first }
    expect(enqueued_args.first).to include("delivery" => hash_including("_aj_globalid"))
    expect(locate_delivery(enqueued_args.first)).to eq(Delivery.first)

    expect(enqueued_args.second).to include("delivery" => hash_including("_aj_globalid"))
    expect(locate_delivery(enqueued_args.second)).to eq(Delivery.second)
  end

  def locate_delivery(enqueued_args)
    gid_string = enqueued_args.dig("delivery", "_aj_globalid")
    GlobalID::Locator.locate(gid_string)
  end
end
