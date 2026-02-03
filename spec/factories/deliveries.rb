FactoryBot.define do
  factory :delivery do
    delivery_reference { Faker::Alphanumeric.alphanumeric }
  end
end
