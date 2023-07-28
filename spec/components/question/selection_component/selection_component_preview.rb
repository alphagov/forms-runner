class Question::SelectionComponent::SelectionComponentPreview < ViewComponent::Preview
  def select_multiple_from_a_list_field
    question = OpenStruct.new(selection: "",
                              answer_type: "selection",
                              is_optional?: false,
                              question_text_with_optional_suffix: "Which countries are part of United Kingdom?",
                              answer_settings: DataStruct.new(only_one_option: "true",
                                                              selection_options: [
                                                                DataStruct.new(name: "England"),
                                                                DataStruct.new(name: "Scotland"),
                                                                DataStruct.new(name: "Wales"),
                                                                DataStruct.new(name: "Northern Ireland"),
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
                              answer_settings: DataStruct.new(only_one_option: "true",
                                                              selection_options: [
                                                                DataStruct.new(name: "England"),
                                                                DataStruct.new(name: "Scotland"),
                                                                DataStruct.new(name: "Wales"),
                                                                DataStruct.new(name: "Northern Ireland"),
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
                              answer_settings: DataStruct.new(only_one_option: "true",
                                                              selection_options: [
                                                                DataStruct.new(name: "England"),
                                                                DataStruct.new(name: "Scotland"),
                                                                DataStruct.new(name: "Wales"),
                                                                DataStruct.new(name: "Northern Ireland"),
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
                              answer_settings: DataStruct.new(only_one_option: "true",
                                                              selection_options: [
                                                                DataStruct.new(name: "England"),
                                                                DataStruct.new(name: "Scotland"),
                                                                DataStruct.new(name: "Wales"),
                                                                DataStruct.new(name: "Northern Ireland"),
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
                              answer_settings: DataStruct.new(only_one_option: false,
                                                              selection_options: [
                                                                DataStruct.new(name: "Yes"),
                                                                DataStruct.new(name: "No"),
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
                              answer_settings: DataStruct.new(only_one_option: false,
                                                              selection_options: [
                                                                DataStruct.new(name: "Yes"),
                                                                DataStruct.new(name: "No"),
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
                              answer_settings: DataStruct.new(only_one_option: false,
                                                              selection_options: [
                                                                DataStruct.new(name: "England"),
                                                                DataStruct.new(name: "France"),
                                                                DataStruct.new(name: "Spain"),
                                                                DataStruct.new(name: "Ireland"),
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
                              answer_settings: DataStruct.new(only_one_option: false,
                                                              selection_options: [
                                                                DataStruct.new(name: "England"),
                                                                DataStruct.new(name: "France"),
                                                                DataStruct.new(name: "Spain"),
                                                                DataStruct.new(name: "Ireland"),
                                                              ]))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::SelectionComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end
end
