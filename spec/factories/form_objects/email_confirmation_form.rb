FactoryBot.define do
  factory :email_confirmation_form, class: "EmailConfirmationForm" do
    send_confirmation { nil }
    confirmation_email_address { nil }
    notify_reference { nil }
    confirmation_email_reference { nil }

    factory :email_confirmation_form_opted_in do
      send_confirmation { "send_email" }
      confirmation_email_address { Faker::Internet.email }
    end
  end
end
