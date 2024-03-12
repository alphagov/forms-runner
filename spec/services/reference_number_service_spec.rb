require "rails_helper"

RSpec.describe ReferenceNumberService do
  describe ".genereate" do
    it "generates an 8 character string" do
      expect(described_class.generate.length).to eq(8)
    end

    it "generates the 3rd and 6th characters as digits" do
      result = described_class.generate
      digit_regex = /\d/
      expect(result[2]).to match(digit_regex)
      expect(result[5]).to match(digit_regex)
    end
  end
end
