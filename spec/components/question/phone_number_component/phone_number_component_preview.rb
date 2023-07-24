class Question::PhoneNumberComponent::PhoneNumberComponentPreview < ViewComponent::Preview
  def phone_number_field
    question = OpenStruct.new(phone_number: "0207 555 4444",
                              answer_type: "phone_number",
                              question_text_with_optional_suffix: "What is your home phone number?",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::PhoneNumberComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def phone_number_field_with_hint
    question = OpenStruct.new(phone_number: "0207 555 4444",
                              answer_type: "phone_number",
                              question_text_with_optional_suffix: "What is your home phone number?",
                              hint_text: "Do not include international dialing code",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::PhoneNumberComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end
end
