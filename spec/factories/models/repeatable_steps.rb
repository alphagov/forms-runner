FactoryBot.define do
  factory :repeatable_step, class: "RepeatableStep" do
    page { association :page }
    question { build(:full_name_question) }

    initialize_with { new(question:, page:) }
  end
end
