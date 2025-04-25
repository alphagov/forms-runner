FactoryBot.define do
  factory :submission do
    created_at { Faker::Time.between(from: Time.zone.local(2025, 1, 1), to: Time.zone.now) }
    updated_at { created_at }
    reference { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
    form_id { 1 }
    answers do
      {
        "1" => {
          selection: "Option 1",
        },
        "2" => {
          text: "Example text",
        },
      }
    end
    mode { "live" }
    form_document { build :v2_form_document }
    mail_status { :pending }

    trait :sent do
      mail_message_id { Faker::Alphanumeric.alphanumeric }
    end
  end
end
