class Question::DateComponent::DateComponentPreview < ViewComponent::Preview
  def other_date_field
    question = OpenStruct.new(date: Date.new(2023, 1, 31),
                              answer_type: "date",
                              question_text_with_optional_suffix: "When did you purchase the vehicle?",
                              answer_settings: OpenStruct.new(input_type: "other_date"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::DateComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def other_date_field_with_hint
    question = OpenStruct.new(date: Date.new(2023, 1, 31),
                              answer_type: "date",
                              question_text_with_optional_suffix: "When did you purchase the vehicle?",
                              hint_text: "For example, 27 3 2007",
                              answer_settings: OpenStruct.new(input_type: "other_date"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::DateComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def date_of_birth_field
    question = OpenStruct.new(date: Date.new(1984, 1, 31),
                              answer_type: "date",
                              question_text_with_optional_suffix: "When were you born?",
                              answer_settings: OpenStruct.new(input_type: "date_of_birth"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::DateComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def date_of_birth_field_with_hint
    question = OpenStruct.new(date: Date.new(1984, 1, 31),
                              answer_type: "date",
                              question_text_with_optional_suffix: "When were you born?",
                              hint_text: "For example, 27 3 1908",
                              answer_settings: OpenStruct.new(input_type: "date_of_birth"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::DateComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end
end
