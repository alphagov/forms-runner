FactoryBot.define do
  factory :selection, class: "Question::Selection" do
    question_text { Faker::Lorem.question }
    hint_text { nil }
    is_optional { false }
    none_of_the_above_answer { nil }
    answer_settings do
      if none_of_the_above_question
        Struct.new(:only_one_option, :selection_options, :none_of_the_above_question)
              .new(only_one_option, selection_options, none_of_the_above_question)
      else
        Struct.new(:only_one_option, :selection_options).new(only_one_option, selection_options)
      end
    end

    transient do
      only_one_option { "true" }
      selection_options { [DataStruct.new(name: "Option 1", value: "Option 1"), DataStruct.new(name: "Option 2", value: "Option 2")] }
      none_of_the_above_question { nil }
    end

    trait :with_hints do
      hint_text { Faker::Quote.yoda }
    end

    trait :with_guidance do
      page_heading { Faker::Quote.yoda }
      guidance_markdown { "## List of items \n\n\n #{Faker::Markdown.ordered_list}" }
    end

    trait :with_none_of_the_above_question do
      transient do
        none_of_the_above_question_text { Faker::Lorem.question }
        none_of_the_above_question_is_optional { "false" }
      end
      is_optional { true }
      none_of_the_above_question do
        Struct.new(:question_text, :is_optional)
              .new(none_of_the_above_question_text, none_of_the_above_question_is_optional)
      end
    end

    factory :single_selection_question do
      only_one_option { "true" }
    end

    factory :multiple_selection_question do
      only_one_option { "false" }
      selection { ["Option 1", "Option 2"] }
    end
  end
end
