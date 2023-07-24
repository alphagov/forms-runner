class Question::TextComponent::TextComponentPreview < ViewComponent::Preview
  def short_text_field
    question = OpenStruct.new(text: "This is a short answer text field",
                              answer_type: "text",
                              question_text_with_optional_suffix: "Summary of your request",
                              answer_settings: OpenStruct.new(input_type: "single_line"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::TextComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def short_text_field_with_hint
    question = OpenStruct.new(text: "This is a short answer text field",
                              answer_type: "text",
                              question_text_with_optional_suffix: "Summary of your request",
                              hint_text: "Please be specific",
                              answer_settings: OpenStruct.new(input_type: "single_line"))
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::TextComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def multiline_text_field
    question = OpenStruct.new(text: "This is a multi-line answer text area. \n\n With examples",
                              answer_type: "text",
                              question_text_with_optional_suffix: "Details of your request",
                              answer_settings: OpenStruct.new)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::TextComponent::View.new(form_builder:, question:, extra_question_text_suffix: nil))
  end

  def multiline_text_field_with_hints
    question = OpenStruct.new(text: "This is a multi-line answer text area. \n\n With examples",
                              answer_type: "text",
                              question_text_with_optional_suffix: "Details of your request (optional)",
                              hint_text: "Add as much details are you like",
                              answer_settings: OpenStruct.new)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::TextComponent::View.new(form_builder:, question:, extra_question_text_suffix: nil))
  end
end
