FactoryBot.define do
  factory :step, class: "Step" do
    page { association :page }
    sequence(:page_slug) { |n| "page-#{n}" }
    question { build(:full_name_question) }
    next_page_slug { nil }

    initialize_with { new(question:, page:, next_page_slug:, page_slug:) }
  end
end
