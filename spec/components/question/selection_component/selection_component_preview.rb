class Question::SelectionComponent::SelectionComponentPreview < ViewComponent::Preview
  def select_multiple_from_a_list_field
    question = OpenStruct.new(selection: "",
                              answer_type: "selection",
                              is_optional?: false,
                              question_text_with_optional_suffix: "Which countries are part of United Kingdom?",
                              answer_settings: OpenStruct.new(only_one_option: "true",
                                                              selection_options: [
                                                                OpenStruct.new(name: "England"),
                                                                OpenStruct.new(name: "Scotland"),
                                                                OpenStruct.new(name: "Wales"),
                                                                OpenStruct.new(name: "Northern Ireland"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def select_multiple_from_a_list_field_with_hint
    question = OpenStruct.new(selection: "",
                              answer_type: "selection",
                              is_optional?: false,
                              question_text_with_optional_suffix: "Which countries are part of United Kingdom?",
                              hint_text: "Select one or more options",
                              answer_settings: OpenStruct.new(only_one_option: "true",
                                                              selection_options: [
                                                                OpenStruct.new(name: "England"),
                                                                OpenStruct.new(name: "Scotland"),
                                                                OpenStruct.new(name: "Wales"),
                                                                OpenStruct.new(name: "Northern Ireland"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def select_multiple_from_a_list_optional_field
    question = OpenStruct.new(selection: "",
                              answer_type: "selection",
                              is_optional?: true,
                              question_text_with_optional_suffix: "Which countries are part of United Kingdom?",
                              answer_settings: OpenStruct.new(only_one_option: "true",
                                                              selection_options: [
                                                                OpenStruct.new(name: "England"),
                                                                OpenStruct.new(name: "Scotland"),
                                                                OpenStruct.new(name: "Wales"),
                                                                OpenStruct.new(name: "Northern Ireland"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def select_multiple_from_a_list_optional_field_with_hint
    question = OpenStruct.new(selection: "",
                              answer_type: "selection",
                              is_optional?: true,
                              question_text_with_optional_suffix: "Which countries are part of United Kingdom?",
                              hint_text: "This is a trick question...",
                              answer_settings: OpenStruct.new(only_one_option: "true",
                                                              selection_options: [
                                                                OpenStruct.new(name: "England"),
                                                                OpenStruct.new(name: "Scotland"),
                                                                OpenStruct.new(name: "Wales"),
                                                                OpenStruct.new(name: "Northern Ireland"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def select_single_from_a_list_field
    question = OpenStruct.new(selection: "No",
                              answer_type: "selection",
                              is_optional?: false,
                              question_text_with_optional_suffix: "Are you sure?",
                              answer_settings: OpenStruct.new(only_one_option: false,
                                                              selection_options: [
                                                                OpenStruct.new(name: "Yes"),
                                                                OpenStruct.new(name: "No"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def select_single_from_a_list_field_with_hint
    question = OpenStruct.new(selection: "No",
                              answer_type: "selection",
                              is_optional?: false,
                              question_text_with_optional_suffix: "Have you recently been involved in a car accident?",
                              hint_text: "Anytime within the last 12 months",
                              answer_settings: OpenStruct.new(only_one_option: false,
                                                              selection_options: [
                                                                OpenStruct.new(name: "Yes"),
                                                                OpenStruct.new(name: "No"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def select_single_from_a_list_optional_field
    question = OpenStruct.new(selection: "England",
                              answer_type: "selection",
                              is_optional?: true,
                              question_text_with_optional_suffix: "Which country is part of United Kingdom?",
                              answer_settings: OpenStruct.new(only_one_option: false,
                                                              selection_options: [
                                                                OpenStruct.new(name: "England"),
                                                                OpenStruct.new(name: "France"),
                                                                OpenStruct.new(name: "Spain"),
                                                                OpenStruct.new(name: "Ireland"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def select_single_from_a_list_optional_field_with_hint
    question = OpenStruct.new(selection: "England",
                              answer_type: "selection",
                              is_optional?: true,
                              question_text_with_optional_suffix: "Which country is part of United Kingdom?",
                              hint_text: "This is a trick question...",
                              answer_settings: OpenStruct.new(only_one_option: false,
                                                              selection_options: [
                                                                OpenStruct.new(name: "England"),
                                                                OpenStruct.new(name: "France"),
                                                                OpenStruct.new(name: "Spain"),
                                                                OpenStruct.new(name: "Ireland"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def select_single_with_more_than_30_options
    selection_options = [
      OpenStruct.new(name: "Mexico"),
      OpenStruct.new(name: "Midway Islands"),
      OpenStruct.new(name: "Moldova"),
      OpenStruct.new(name: "Monaco"),
      OpenStruct.new(name: "Mongolia"),
      OpenStruct.new(name: "Montenegro"),
      OpenStruct.new(name: "Montserrat"),
      OpenStruct.new(name: "Morocco"),
      OpenStruct.new(name: "Mozambique"),
      OpenStruct.new(name: "Myanmar (Burma)"),
      OpenStruct.new(name: "Namibia"),
      OpenStruct.new(name: "Nauru"),
      OpenStruct.new(name: "Navassa Island"),
      OpenStruct.new(name: "Nepal"),
      OpenStruct.new(name: "Netherlands"),
      OpenStruct.new(name: "New Caledonia"),
      OpenStruct.new(name: "New Zealand"),
      OpenStruct.new(name: "Nicaragua"),
      OpenStruct.new(name: "Niger"),
      OpenStruct.new(name: "Nigeria"),
      OpenStruct.new(name: "Niue"),
      OpenStruct.new(name: "Norfolk Island"),
      OpenStruct.new(name: "Northern Mariana Islands"),
      OpenStruct.new(name: "North Korea"),
      OpenStruct.new(name: "North Macedonia"),
      OpenStruct.new(name: "Norway"),
      OpenStruct.new(name: "Occupied Palestinian Territories"),
      OpenStruct.new(name: "Oman"),
      OpenStruct.new(name: "Pakistan"),
      OpenStruct.new(name: "Palau"),
      OpenStruct.new(name: "Palmyra Atoll"),
      OpenStruct.new(name: "Panama"),
      OpenStruct.new(name: "Papua New Guinea"),
      OpenStruct.new(name: "Paraguay"),
      OpenStruct.new(name: "Peru"),
      OpenStruct.new(name: "Philippines"),
    ]

    question = OpenStruct.new(selection: "",
                              answer_type: "selection",
                              is_optional?: false,
                              question_text_with_optional_suffix: "Which of these countries do you live in?",
                              hint_text: "Select an option",
                              selection_options_with_none_of_the_above: selection_options,
                              answer_settings: OpenStruct.new(only_one_option: "true",
                                                              selection_options:))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end
end
