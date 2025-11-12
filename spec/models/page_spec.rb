require "rails_helper"

RSpec.describe Page, type: :model do
  it "has a valid factory" do
    page = build :page
    expect(page).to be_valid
  end

  describe "#answer_settings" do
    it "returns an empty object for answer_settings when it's not present" do
      page = described_class.new
      expect(page).to have_attributes(answer_settings: {})
    end

    it "returns an answer settings object for answer_settings when present" do
      page = described_class.new(answer_settings: { only_one_option: "true" })
      expect(page.answer_settings.attributes).to eq({ "only_one_option" => "true" })
    end
  end

  describe "#repeatable?" do
    it "returns false when attribute does not exist" do
      page = described_class.new
      expect(page.repeatable?).to be false
    end

    it "returns false when attribute is false" do
      page = described_class.new is_repeatable: false
      expect(page.repeatable?).to be false
    end

    it "returns true when attribute is true" do
      page = described_class.new is_repeatable: true
      expect(page.repeatable?).to be true
    end
  end

  describe Page::PAGE_ID_REGEX do
    it "matches valid page_id values" do
      %w[1 123 0123456789 08suZ3aP].each do |string|
        expect(described_class).to match string
      end
    end

    it "does not match invalid page_id values" do
      %w[no%20ten toolongforanid0 check_your_answers /secret/login.php].each do |string|
        expect(described_class).not_to match string
      end
    end
  end
end
