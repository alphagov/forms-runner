require "rails_helper"

RSpec.describe Question::Name, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, answer_settings:, question_text: } }
  let(:answer_settings) { OpenStruct.new({ input_type:, title_needed: }) }
  let(:input_type) { "full_name" }
  let(:title_needed) { "false" }
  let(:question_text) { "What is your name?" }
  let(:is_optional) { false }

  it_behaves_like "a question model"

  context "when the name question is in full name format" do
    context "when the answer is empty" do
      it "returns invalid with blank full_name field" do
        expect(question).not_to be_valid
        expect(question.errors[:full_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.full_name.blank"))
      end

      it "returns invalid with empty string full_name field" do
        question.full_name = ""
        expect(question).not_to be_valid
        expect(question.errors[:full_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.full_name.blank"))
      end

      it "returns \"\" for show_answer" do
        expect(question.show_answer).to eq ""
      end

      it "returns a hash containing a blank value for the full name field" do
        expect(question.show_answer_in_csv).to eq({ "What is your name? - Full name" => "" })
      end
    end

    context "when the answer is valid" do
      let(:name) { Faker::Name.name }

      before do
        question.full_name = name
      end

      it "returns valid" do
        expect(question).to be_valid
        expect(question.errors[:full_name]).to be_empty
      end

      it "returns the full name for show_answer" do
        expect(question.show_answer).to eq(name)
      end

      it "returns the labelled individual parts in show_answer_for_email" do
        expect(question.show_answer_in_email).to eq("Full name: #{name}")
      end

      it "returns a hash with the full name for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq({ "#{question_text} - Full name" => name })
      end
    end
  end

  context "when the name question is in first and last name format" do
    let(:input_type) { "first_and_last_name" }

    context "when the answer is empty" do
      it "returns invalid with blank first and last name fields" do
        expect(question).not_to be_valid
        expect(question.errors[:first_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.first_name.blank"))
        expect(question.errors[:last_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.last_name.blank"))
      end

      it "returns invalid with empty string first and last name fields" do
        question.first_name = ""
        question.last_name = ""
        expect(question).not_to be_valid
        expect(question.errors[:first_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.first_name.blank"))
        expect(question.errors[:last_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.last_name.blank"))
      end

      it "returns \"\" for show_answer" do
        expect(question.show_answer).to eq ""
      end

      it "returns a hash containing a blank value for the first and last name fields" do
        expect(question.show_answer_in_csv).to eq({
          "What is your name? - First name" => "",
          "What is your name? - Last name" => "",
        })
      end
    end

    context "when the question is optional" do
      let(:is_optional) { true }

      it "allows the user to skip the question" do
        question.first_name = ""
        question.last_name = ""
        expect(question).to be_valid
        expect(question.errors[:first_name]).to be_empty
        expect(question.errors[:last_name]).to be_empty
      end

      it "returns invalid if the question is partially filled in" do
        question.first_name = Faker::Name.first_name
        question.last_name = ""
        expect(question).not_to be_valid
        expect(question.errors[:last_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.last_name.blank"))
      end

      it "returns a hash with blank fields for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq({
          "What is your name? - First name" => "",
          "What is your name? - Last name" => "",
        })
      end
    end

    context "when the answer is valid" do
      let(:name) { "#{first_name} #{last_name}" }
      let(:first_name) { Faker::Name.first_name }
      let(:last_name) { Faker::Name.last_name }

      before do
        question.first_name = first_name
        question.last_name = last_name
      end

      it "returns valid" do
        expect(question).to be_valid
        expect(question.errors[:first_name]).to be_empty
        expect(question.errors[:last_name]).to be_empty
      end

      it "returns the full name for show_answer" do
        expect(question.show_answer).to eq(name)
      end

      it "returns the labelled individual parts in show_answer_for_email" do
        expect(question.show_answer_in_email).to eq("First name: #{first_name}\n\nLast name: #{last_name}")
      end

      it "returns a hash with the first and last name for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq({
          "#{question_text} - First name" => first_name,
          "#{question_text} - Last name" => last_name,
        })
      end
    end
  end

  context "when the name question is in first, middle and last name format" do
    let(:input_type) { "first_middle_and_last_name" }

    context "when the answer is empty" do
      it "returns invalid with blank first and last name fields" do
        expect(question).not_to be_valid
        expect(question.errors[:first_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.first_name.blank"))
        expect(question.errors[:last_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.last_name.blank"))
      end

      it "returns invalid with empty string first and last name fields" do
        question.first_name = ""
        question.last_name = ""
        expect(question).not_to be_valid
        expect(question.errors[:first_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.first_name.blank"))
        expect(question.errors[:last_name]).to include(I18n.t("activemodel.errors.models.question/name.attributes.last_name.blank"))
      end

      it "returns \"\" for show_answer" do
        expect(question.show_answer).to eq ""
      end

      it "returns a hash containing a blank value for the first, middle and last name fields" do
        expect(question.show_answer_in_csv).to eq({
          "What is your name? - First name" => "",
          "What is your name? - Middle names" => "",
          "What is your name? - Last name" => "",
        })
      end
    end

    context "when the answer is valid" do
      let(:name) { "#{first_name} #{middle_name} #{last_name}" }
      let(:first_name) { Faker::Name.first_name }
      let(:middle_name) { Faker::Name.middle_name }
      let(:last_name) { Faker::Name.last_name }

      before do
        question.first_name = first_name
        question.middle_names = middle_name
        question.last_name = last_name
      end

      it "returns valid" do
        expect(question).to be_valid
        expect(question.errors[:first_name]).to be_empty
        expect(question.errors[:middle_names]).to be_empty
        expect(question.errors[:last_name]).to be_empty
      end

      it "returns the full name for show_answer" do
        expect(question.show_answer).to eq(name)
      end

      it "returns the labelled individual parts in show_answer_for_email" do
        expect(question.show_answer_in_email).to eq("First name: #{first_name}\n\nMiddle names: #{middle_name}\n\nLast name: #{last_name}")
      end

      it "returns a hash with the first, middle and last name for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq({
          "#{question_text} - First name" => first_name,
          "#{question_text} - Middle names" => middle_name,
          "#{question_text} - Last name" => last_name,
        })
      end
    end
  end

  context "when title_needed is set to true" do
    let(:title_needed) { "true" }

    context "when the name question is in full name format" do
      let(:name) { Faker::Name.name }

      context "when title is blank" do
        before do
          question.title = ""
          question.full_name = name
        end

        it "allows the user to enter a blank title" do
          expect(question).to be_valid
        end

        it "returns the full name for show_answer" do
          expect(question.show_answer).to eq(name)
        end

        it "returns the labelled individual parts in show_answer_for_email" do
          expect(question.show_answer_in_email).to eq("Full name: #{name}")
        end

        it "returns a hash with a blank value for the title and the full name for show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq({
            "#{question_text} - Title" => "",
            "#{question_text} - Full name" => name,
          })
        end
      end

      context "when title is set" do
        let(:title) { Faker::Name.prefix }

        before do
          question.title = title
          question.full_name = name
        end

        it "returns the full name for show_answer" do
          expect(question.show_answer).to eq("#{title} #{name}")
        end

        it "returns the labelled individual parts in show_answer_for_email" do
          expect(question.show_answer_in_email).to eq("Title: #{title}\n\nFull name: #{name}")
        end

        it "returns a hash with the full name and title for show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq({
            "#{question_text} - Full name" => name,
            "#{question_text} - Title" => title,
          })
        end
      end
    end

    context "when the name question is in first and last name format" do
      let(:input_type) { "first_and_last_name" }
      let(:first_name) { Faker::Name.first_name }
      let(:last_name) { Faker::Name.last_name }

      before do
        question.title = title
        question.first_name = first_name
        question.last_name = last_name
      end

      context "when title is blank" do
        let(:title) { nil }

        it "allows the user to enter a blank title" do
          expect(question).to be_valid
        end

        it "returns the full name for show_answer" do
          expect(question.show_answer).to eq("#{first_name} #{last_name}")
        end

        it "returns the labelled individual parts in show_answer_for_email" do
          expect(question.show_answer_in_email).to eq("First name: #{first_name}\n\nLast name: #{last_name}")
        end

        it "returns a hash with the first and last name for show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq({
            "#{question_text} - Title" => "",
            "#{question_text} - First name" => first_name,
            "#{question_text} - Last name" => last_name,
          })
        end
      end

      context "when title is set" do
        let(:title) { Faker::Name.prefix }

        before do
          question.title = title
          question.first_name = first_name
          question.last_name = last_name
        end

        it "returns the full name for show_answer" do
          expect(question.show_answer).to eq("#{title} #{first_name} #{last_name}")
        end

        it "returns the labelled individual parts in show_answer_for_email" do
          expect(question.show_answer_in_email).to eq("Title: #{title}\n\nFirst name: #{first_name}\n\nLast name: #{last_name}")
        end

        it "returns a hash with the first and last name for show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq({
            "#{question_text} - First name" => first_name,
            "#{question_text} - Last name" => last_name,
            "#{question_text} - Title" => title,
          })
        end
      end
    end

    context "when the name question is in first, middle and last name format" do
      let(:input_type) { "first_middle_and_last_name" }
      let(:first_name) { Faker::Name.first_name }
      let(:middle_name) { "#{Faker::Name.middle_name} #{Faker::Name.middle_name}" }
      let(:last_name) { Faker::Name.last_name }

      before do
        question.title = title
        question.first_name = first_name
        question.middle_names = middle_name
        question.last_name = last_name
      end

      context "when title is blank" do
        let(:title) { nil }

        it "allows the user to enter a blank title" do
          expect(question).to be_valid
        end

        it "returns the full name for show_answer" do
          expect(question.show_answer).to eq("#{first_name} #{middle_name} #{last_name}")
        end

        it "returns the labelled individual parts in show_answer_for_email" do
          expect(question.show_answer_in_email).to eq("First name: #{first_name}\n\nMiddle names: #{middle_name}\n\nLast name: #{last_name}")
        end

        it "returns a hash with the first, middle and last name for show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq({
            "#{question_text} - Title" => "",
            "#{question_text} - First name" => first_name,
            "#{question_text} - Middle names" => middle_name,
            "#{question_text} - Last name" => last_name,
          })
        end
      end

      context "when title is set" do
        let(:title) { Faker::Name.prefix }

        before do
          question.title = title
          question.first_name = first_name
          question.middle_names = middle_name
          question.last_name = last_name
        end

        it "returns the full name for show_answer" do
          expect(question.show_answer).to eq("#{title} #{first_name} #{middle_name} #{last_name}")
        end

        it "returns the labelled individual parts in show_answer_for_email" do
          expect(question.show_answer_in_email).to eq("Title: #{title}\n\nFirst name: #{first_name}\n\nMiddle names: #{middle_name}\n\nLast name: #{last_name}")
        end

        it "returns a hash with the first, middle and last name for show_answer_in_csv" do
          expect(question.show_answer_in_csv).to eq({
            "#{question_text} - First name" => first_name,
            "#{question_text} - Middle names" => middle_name,
            "#{question_text} - Last name" => last_name,
            "#{question_text} - Title" => title,
          })
        end
      end
    end
  end
end
