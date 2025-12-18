class Question::NumberComponent::NumberComponentPreview < ViewComponent::Preview
  def number_field
    question = OpenStruct.new(number: "7",
                              answer_type: "number",
                              question_text_with_optional_suffix: "Number of days in a week",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NumberComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end

  def number_field_with_hint
    question = OpenStruct.new(number: "7",
                              answer_type: "number",
                              question_text_with_optional_suffix: "Number of days in a week",
                              hint_text: "Number after 6",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NumberComponent::View.new(form_builder:, question:, mode: Mode.new("form")))
  end
end
