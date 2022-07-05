require "rails_helper"
require "ostruct"
require_relative "../../app/lib/question_register"

RSpec.describe QuestionRegister do
  it "returns a class given a valid answer_type" do
    %i[date single_line address email national_insurance_number phone_number].each do |type|
      page = OpenStruct.new(answer_type: type)
      expect(described_class.from_page(page)).to be_kind_of(Class)
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
end
