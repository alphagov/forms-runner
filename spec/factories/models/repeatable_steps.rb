FactoryBot.define do
  factory :repeatable_step, class: "RepeatableStep" do
    page { association :page }
    sequence(:page_slug) { |n| "page-#{n}" }
    question { build(:full_name_question) }

    initialize_with { new(question:, page:, page_slug:) }
  end
end
