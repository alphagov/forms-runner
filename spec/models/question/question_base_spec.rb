require "rails_helper"

RSpec.describe Question::QuestionBase do
  describe "#answered?" do
    context "when question class has a single answer attribute" do
      let(:question_class) do
        Class.new(described_class) do
          attribute :answer
        end
      end

      it "returns false if question does not have answer data" do
        expect(question_class.new).not_to be_answered
      end

      it "returns true if question has answer data" do
        expect(question_class.new(answer: "Yes")).to be_answered
      end

      it "returns true if question has been answered with blank answer" do
        expect(question_class.new(answer: "")).to be_answered
      end
    end

    context "when question class has more than one answer attribute" do
      let(:question_class) do
        Class.new(described_class) do
          attribute :part1
          attribute :part2
        end
      end

      it "returns true if question has answer data" do
        expect(question_class.new(part1: "Hello", part2: "World")).to be_answered
      end

      it "returns true if question has partial answer data" do
        expect(question_class.new(part1: "Hello")).to be_answered
      end

      it "returns true if question has been answered with blank answer" do
        expect(question_class.new(part1: "", part2: "")).to be_answered
      end
    end
  end
end
