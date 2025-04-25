FactoryBot.define do
  factory :file, class: "Question::File" do
    question_text { Faker::Lorem.question }
    hint_text { nil }
    is_optional { false }
    page_heading { nil }
    guidance_markdown { nil }
    file { nil }
    original_filename { nil }
    uploaded_file_key { nil }

    trait :with_uploaded_file do
      original_filename { Faker::File.file_name(dir: "", directory_separator: "", ext: "txt") }
      uploaded_file_key { Faker::Alphanumeric.alphanumeric }
    end

    trait :with_answer_skipped do
      is_optional { true }
      original_filename { "" }
    end

    trait :with_guidance do
      page_heading { Faker::Lorem.sentence }
      guidance_markdown { Faker::Lorem.paragraph }
    end
  end
end
