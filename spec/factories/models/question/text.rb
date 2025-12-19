FactoryBot.define do
  factory :text, class: "Question::Text" do
    question_text { Faker::Lorem.question }
    hint_text { nil }
    is_optional { false }
    page_heading { nil }
    guidance_markdown { nil }
    text { nil }
    answer_settings { DataStruct.new(input_type:) }

    transient do
      input_type { "single_line" }
    end

    trait :with_answer do
      text { Faker::Lorem.sentence }
    end

    trait :with_long_text do
      input_type { "long_text" }
      text { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    end
  end
end
