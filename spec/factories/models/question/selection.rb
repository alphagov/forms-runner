FactoryBot.define do
  factory :selection, class: "Question::Selection" do
    question_text { Faker::Lorem.question }
    hint_text { nil }
    is_optional { false }

    trait :with_hints do
      hint_text { Faker::Quote.yoda }
    end

    factory :single_selection_question do
      transient do
        selection_options { [DataStruct.new(name: "Option 1"),  DataStruct.new(name: "Option 2")] }
      end
      answer_settings { DataStruct.new(only_one_option: "true", selection_options:) }
    end

    factory :multiple_selection_question do
      transient do
        selection_options { [DataStruct.new(name: "Option 1"),  DataStruct.new(name: "Option 2")] }
      end
      answer_settings { DataStruct.new(only_one_option: "false", selection_options:) }
    end
  end
end
