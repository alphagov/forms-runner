FactoryBot.define do
  factory :v2_step, class: DataStruct do
    id { Faker::Number.number(digits: 2) }

    sequence(:position) { |n| n }
    next_step_id { nil }

    routing_conditions { [] }

    type { nil }
    data { nil }

    factory :v2_question_page_step do
      type { "question_page" }

      transient do
        answer_type { "number" }
        answer_settings { nil }

        question_text { Faker::Lorem.question }

        hint_text { nil }

        guidance_markdown { nil }
        page_heading { nil }

        is_optional { false }
        is_repeatable { false }
      end

      data do
        DataStruct.new(
          answer_settings:,
          answer_type:,
          guidance_markdown:,
          hint_text:,
          is_optional:,
          is_repeatable:,
          page_heading:,
          question_text:,
        )
      end

      trait :with_selections_settings do
        transient do
          only_one_option { "true" }
          selection_options { [{ name: "Option 1", value: "Option 1" }, { name: "Option 2", value: "Option 2" }] }
        end

        answer_type { "selection" }
        answer_settings { DataStruct.new(only_one_option:, selection_options:) }
      end

      trait :with_text_settings do
        transient do
          input_type { %w[single_line long_text].sample }
        end

        answer_type { "text" }
        answer_settings do
          DataStruct.new(
            input_type:,
          )
        end
      end

      trait :with_repeatable do
        is_repeatable { true }
      end
    end
  end
end
