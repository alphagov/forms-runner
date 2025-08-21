FactoryBot.define do
  factory :step, class: "Step" do
    page { association :page }
    question { build(:full_name_question) }

    initialize_with { new(question:, page:) }
  end
end
