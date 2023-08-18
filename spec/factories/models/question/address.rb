FactoryBot.define do
  factory :address, class: "Question::Address" do
    question_text { Faker::Lorem.question }
    hint_text { nil }
    is_optional { false }
    address1 { nil }
    address2 { nil }
    town_or_city { nil }
    county { nil }
    postcode { nil }
    street_address { nil }
    country { nil }
    answer_settings { DataStruct.new(input_type: DataStruct.new(uk_address: "true", international_address: "true")) }

    trait :with_hints do
      hint_text { Faker::Quote.yoda }
    end

    factory :uk_address_question do
      address1 { Faker::Address.street_address }
      address2 { nil }
      town_or_city { Faker::Address.city }
      county { "London" }
      postcode { "SW1H 9AJ" }

      answer_settings { DataStruct.new(input_type: DataStruct.new(uk_address: "true")) }
    end

    factory :international_address_question do
      street_address { "237 Bogisich Way,\nNorth Desmond\nNH 16786" }
      country { "USA" }

      answer_settings { DataStruct.new(input_type: DataStruct.new(international_address: "true")) }
    end
  end
end
