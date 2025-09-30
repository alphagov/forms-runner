FactoryBot.define do
  factory :submission do
    created_at { Time.zone.now - 2.minutes }
    updated_at { created_at }
    last_delivery_attempt { nil }
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
    delivery_status { :pending }

    trait :sent do
      mail_message_id { Faker::Alphanumeric.alphanumeric }
      last_delivery_attempt { created_at + 1.minute }
    end

    trait :bounced do
      sent
      delivery_status { :bounced }
    end
  end
end
