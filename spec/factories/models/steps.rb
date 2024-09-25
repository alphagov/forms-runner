FactoryBot.define do
  factory :step, class: "Step" do
    page { association :page }
    sequence(:page_slug) { |n| "page-#{n}" }
    sequence(:form_slug) { |n| "form-#{n}" }
    form_id { 1 }
    question { build(:full_name_question) }
    next_page_slug { nil }

    initialize_with { new(question:, page:, form_id:, form_slug:, next_page_slug:, page_slug:) }
  end
end
