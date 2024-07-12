require "rails_helper"

RSpec.describe Page, type: :model do
  it "returns the page given a hash" do
    expect(described_class.from_json({ "answer_settings" => { "input_type" => 'text' }, routing_conditions: []}).answer_settings.input_type).to eq('text')
  end
end
