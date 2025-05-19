FactoryBot.define do
  factory :email_confirmation_input, class: "EmailConfirmationInput" do
    send_confirmation { nil }
    confirmation_email_address { nil }
    confirmation_email_reference { "ffffffff-confirmation-email" }

    factory :email_confirmation_input_opted_in do
      send_confirmation { "send_email" }
      confirmation_email_address { Faker::Internet.email }
    end
  end
end
