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
      original_filename { Faker::File.file_name(ext: "txt") }
      uploaded_file_key { Faker::Alphanumeric.alphanumeric }
    end
  end
end
