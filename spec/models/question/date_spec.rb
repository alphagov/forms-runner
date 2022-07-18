require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::Date, type: :model do
  it_behaves_like "a question model"

  context "when a date has an empty day, month and year" do
    it "returns invalid with blank message" do
      question = described_class.new
      question.validate
      expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.blank"))
    end

    it "shows as a blank string" do
      question = described_class.new
      expect(question.show_answer).to eq ""
    end
  end

  context "when a date has empty day, month or year" do
    it "returns invalid with a message" do
      question = described_class.new
      day_month_years = [
        [1, nil, 2022],
        [nil, 1, 2022],
        [1, 1, nil],
      ]

      day_month_years.each do |v|
        question.date_day = v[0]
        question.date_month = v[1]
        question.date_year = v[2]
        question.validate
        expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.blank_date_fields"))
      end
    end
  end

  context "when a date has a valid day, month or year" do
    it "displays date in the correct format" do
      question = described_class.new({ date_day: "31", date_month: "12", date_year: "2021" })
      expect(question.show_answer).to eq "31/12/2021"
    end

    it "is valid" do
      question = described_class.new({ date_day: "31", date_month: "12", date_year: "2021" })
      expect(question).to be_valid
    end
  end

  context "when a date has a valid day, month or year but it's not a real date" do
    it "isn't valid" do
      question = described_class.new({ date_day: "31", date_month: "02", date_year: "2021" })
      question.validate
      expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.invalid_date"))
    end
  end

  context "when given non-integers as values for day, month or year" do
    it "isn't valid" do
      question = described_class.new
      day_month_years = [
        [1, "e", 2022],
        ["pi", 1, 2022],
        [1, 1, "zero"],
      ]

      day_month_years.each do |v|
        question.date_day = v[0]
        question.date_month = v[1]
        question.date_year = v[2]
        question.validate
        expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.invalid_date"))
      end
    end
  end
end
