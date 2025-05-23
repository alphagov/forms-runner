FactoryBot.define do
  factory :v2_form_document, class: DataStruct do
    form_id { Faker::Alphanumeric.alphanumeric(number: 8) }

    sequence(:name) { |n| "Form #{n}" }
    form_slug { name ? name.parameterize : nil }

    steps { [] }

    declaration_text { nil }
    declaration_section_completed { false }
    payment_url { nil }
    privacy_policy_url { nil }
    submission_email { nil }
    submission_type { nil }
    support_email { nil }
    support_phone { nil }
    support_url { nil }
    support_url_text { nil }
    question_section_completed { false }
    what_happens_next_markdown { nil }
    language { "en" }

    trait :with_steps do
      transient do
        steps_count { 5 }
      end

      steps do
        Array.new(steps_count) { attributes_for(:v2_step) }
      end

      question_section_completed { true }
    end

    trait :with_privacy_policy_url do
      privacy_policy_url { Faker::Internet.url host: "gov.uk" }
    end

    trait :with_submission_email do
      submission_email { Faker::Internet.email domain: "example.gov.uk" }
    end

    trait :with_support do
      support_email { Faker::Internet.email(domain: "example.gov.uk") }
      support_phone { Faker::Lorem.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) }
      support_url { Faker::Internet.url(host: "gov.uk") }
      support_url_text { Faker::Lorem.sentence(word_count: 1, random_words_to_add: 4) }
    end

    trait :ready_for_live do
      with_steps
      with_privacy_policy_url
      with_submission_email
      support_email { Faker::Internet.email(domain: "example.gov.uk") }
      what_happens_next_markdown { "We usually respond to applications within 10 working days." }
    end

    trait :live? do
      ready_for_live
      live_at { Time.zone.now }
    end
  end
end
