require "rails_helper"

RSpec.describe Question::Date, type: :model do
  let(:options) { {} }
  subject(:question) { described_class.new({}, options) }

  it_behaves_like "a question model"

  context "when a date has an empty day, month and year" do
    it "returns invalid with blank date" do
      expect(question).not_to be_valid
      expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.blank"))
    end

    it "returns invalid with empty string" do
      set_date("", "", "")
      expect(question).not_to be_valid
      expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.blank"))
    end

    it "shows as a blank string" do
      expect(question.show_answer).to eq ""
    end
  end

  context "when a date has empty day, month or year" do
    it "returns invalid with a message" do
      day_month_years = [
        [1, nil, 2022],
        [nil, 1, 2022],
        [1, 1, nil],
      ]

      day_month_years.each do |v|
        set_date(*v)
        expect(question).not_to be_valid
        expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.blank_date_fields"))
      end
    end
  end

  context "when a date has a valid day, month or year" do
    before do
      set_date("31", "12", "2021")
    end

    it "displays date in the correct format" do
      expect(question.show_answer).to eq "31/12/2021"
    end

    it "is valid" do
      expect(question).to be_valid
    end
  end

  context "when a date has a valid day, month or year but it's not a real date" do
    before do
      set_date("45", "02", "2021")
    end

    it "isn't valid" do
      expect(question).not_to be_valid
      expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.invalid_date"))
    end
  end

  context "when given non-integers as values for day, month or year" do
    it "isn't valid" do
      day_month_years = [
        [1, "e", 2022],
        ["pi", 1, 2022],
        [1, 1, "zero"],
      ]

      day_month_years.each do |v|
        set_date(*v)
        expect(question).not_to be_valid
        expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.invalid_date"))
      end
    end
  end

  context "when question is optional" do
    let(:options) { { is_optional: true } }

    it "returns valid with blank date" do
      expect(question).to be_valid
      expect(question.errors[:date]).to_not include(I18n.t("activemodel.errors.models.question/date.attributes.date.blank"))
    end

    it "returns valid with empty string" do
      set_date("", "", "")
      expect(question).to be_valid
      expect(question.errors[:date]).not_to include(I18n.t("activemodel.errors.models.question/date.attributes.date.blank"))
    end

    context "when a date has empty day, month or year" do
      it "returns invalid with a message" do
        day_month_years = [
          [1, nil, 2022],
          [nil, 1, 2022],
          [1, 1, nil],
        ]

        day_month_years.each do |v|
          set_date(*v)
          expect(question).not_to be_valid
          expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.blank_date_fields"))
        end
      end
    end

    context "when a date has a valid day, month or year" do
      before do
        set_date("31", "12", "2021")
      end

      it "displays date in the correct format" do
        expect(question.show_answer).to eq "31/12/2021"
      end

      it "is valid" do
        expect(question).to be_valid
      end
    end

    context "when a date has a valid day, month or year but it's not a real date" do
      before do
        set_date("45", "02", "2021")
      end

      it "isn't valid" do
        expect(question).not_to be_valid
        expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.invalid_date"))
      end
    end

    context "when given non-integers as values for day, month or year" do
      it "isn't valid" do
        day_month_years = [
          [1, "e", 2022],
          ["pi", 1, 2022],
          [1, 1, "zero"],
        ]

        day_month_years.each do |v|
          set_date(*v)
          expect(question).not_to be_valid
          expect(question.errors[:date]).to include(I18n.t("activemodel.errors.models.question/date.attributes.date.invalid_date"))
        end
      end
    end
  end

private

  def set_date(day, month, year)
    question.date_day = day
    question.date_month = month
    question.date_year = year
  end
end
