FactoryBot.define do
  factory :text, class: "Question::Text" do
    question_text { Faker::Lorem.question }
    hint_text { nil }
    is_optional { false }
    page_heading { nil }
    guidance_markdown { nil }
    text { nil }

    trait :with_answer do
      text { Faker::Lorem.sentence }
    end
  end
end
