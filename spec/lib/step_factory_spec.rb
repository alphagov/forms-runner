require "rails_helper"

RSpec.describe StepFactory do
  describe StepFactory::PAGE_SLUG_REGEX do
    it "matches valid page_id values" do
      %w[1 123 0123456789 check_your_answers].each do |string|
        expect(described_class.match(string)).to be_truthy
      end
    end

    it "does not match invalid page_id values" do
      %w[no ten inspect_your_answers /secret/login.php].each do |string|
        expect(described_class.match(string)).to be_falsy
      end
    end
  end
end
