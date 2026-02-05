FactoryBot.define do
  factory :delivery do
    delivery_reference { Faker::Alphanumeric.alphanumeric }
    created_at { Time.current }

    trait :pending do
      delivered_at { nil }
      failed_at { nil }
    end

    trait :delivered do
      delivered_at { created_at + 5.minutes }
      failed_at { nil }
    end

    trait :failed do
      delivered_at { nil }
      failed_at { created_at + 5.minutes }
      failure_reason { "example" }
    end

    trait :delivered_after_failure do
      failed_at { created_at + 5.minutes }
      delivered_at { created_at + 10.minutes }
      failure_reason { "example" }
    end

    trait :failed_after_delivery do
      delivered_at { created_at + 5.minutes }
      failed_at { created_at + 10.minutes }
      failure_reason { "example" }
    end
  end
end
