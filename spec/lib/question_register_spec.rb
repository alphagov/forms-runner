require "rails_helper"
require "ostruct"

RSpec.describe QuestionRegister do
  it "returns a class given a valid answer_type" do
    %i[date address email national_insurance_number phone_number number organisation_name text].each do |type|
      page = OpenStruct.new(answer_type: type)
      expect { described_class.from_page(page) }.not_to raise_error
    end
  end

  it "raises ArgumentError when given an invalid argument type" do
    page = OpenStruct.new(answer_type: :invalid_type)
    expect { described_class.from_page(page) }.to raise_error(ArgumentError)
  end

  it "raises NoMethodError when when not given an object which reponds to answer_type" do
    page = nil
    expect { described_class.from_page(page) }.to raise_error(NoMethodError)
  end

  it "accepts is_optional for each answer_type" do
    [false, true].each do |is_optional|
      %i[date address email national_insurance_number phone_number number organisation_name text].each do |type|
        page = OpenStruct.new(answer_type: type, is_optional:)
        expect(described_class.from_page(page).is_optional?).to eq(is_optional)
      end
    end
  end
end
