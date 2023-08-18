class Question::NameComponent::NameComponentPreview < ViewComponent::Preview
  def full_name_with_no_title_field
    question = OpenStruct.new(full_name: "Joe Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your full name?",
                              answer_settings: OpenStruct.new(input_type: "full_name", title_needed: "false"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def full_name_with_no_title_field_with_hint
    question = OpenStruct.new(full_name: "Joe Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your full name?",
                              hint_text: "Must full name as it appears in your passport",
                              answer_settings: OpenStruct.new(input_type: "full_name", title_needed: "false"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def full_name_with_title_field
    question = OpenStruct.new(full_name: "Joe Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your full name with title?",
                              answer_settings: OpenStruct.new(input_type: "full_name", title_needed: "true"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def full_name_with_title_field_with_hint
    question = OpenStruct.new(full_name: "Joe Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your full name with title?",
                              hint_text: "Must full name as it appears in your passport",
                              answer_settings: OpenStruct.new(input_type: "full_name", title_needed: "true"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def first_and_last_name_with_title_field
    question = OpenStruct.new(first_name: "Joe",
                              last_name: "Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your first/last name with title?",
                              answer_settings: OpenStruct.new(input_type: "first_and_last_name", title_needed: "true"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def first_and_last_name_with_title_field_with_hint
    question = OpenStruct.new(first_name: "Joe",
                              last_name: "Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your first/last name with title?",
                              hint_text: "Must be first/last name as it appears in your passport",
                              answer_settings: OpenStruct.new(input_type: "first_and_last_name", title_needed: "true"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def first_and_last_name_with_no_title_field
    question = OpenStruct.new(first_name: "Joe",
                              last_name: "Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your first/last name?",
                              answer_settings: OpenStruct.new(input_type: "first_and_last_name", title_needed: "false"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def first_and_last_name_with_no_title_field_with_hint
    question = OpenStruct.new(first_name: "Joe",
                              last_name: "Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your first/last name?",
                              hint_text: "Must be first/last name as it appears in your passport",
                              answer_settings: OpenStruct.new(input_type: "first_and_last_name", title_needed: "false"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def first_middle_and_last_name_with_title_field
    question = OpenStruct.new(first_name: "Joe",
                              middle_names: "average",
                              last_name: "Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your first/middle/last name with title?",
                              answer_settings: OpenStruct.new(input_type: "first_middle_and_last_name", title_needed: "true"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def first_middle_and_last_name_with_title_field_with_hint
    question = OpenStruct.new(first_name: "Joe",
                              middle_names: "average",
                              last_name: "Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your first/middle/last name with title?",
                              hint_text: "Must be first/last name as it appears in your passport",
                              answer_settings: OpenStruct.new(input_type: "first_middle_and_last_name", title_needed: "true"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def first_middle_and_last_name_with_no_title_field
    question = OpenStruct.new(first_name: "Joe",
                              middle_names: "average",
                              last_name: "Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your first/middle/last name?",
                              answer_settings: OpenStruct.new(input_type: "first_middle_and_last_name", title_needed: "false"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def first_middle_and_last_name_with_no_title_field_with_hint
    question = OpenStruct.new(first_name: "Joe",
                              middle_names: "average",
                              last_name: "Bloggs",
                              answer_type: "name",
                              question_text_with_optional_suffix: "What is your first/last name?",
                              hint_text: "Must be first/last name as it appears in your passport",
                              answer_settings: OpenStruct.new(input_type: "first_middle_and_last_name", title_needed: "false"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end
end
