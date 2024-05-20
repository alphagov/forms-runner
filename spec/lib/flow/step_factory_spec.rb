require "rails_helper"

RSpec.describe Flow::StepFactory do
  describe Flow::StepFactory::PAGE_SLUG_REGEX do
    it "matches valid page_id values" do
      %w[1 123 0123456789 check-your-answers].each do |string|
        expect(described_class).to match string
      end
    end

    it "does not match invalid page_id values" do
      %w[no ten inspect_your_answers /secret/login.php].each do |string|
        expect(described_class).not_to match string
      end
    end
  end
end
