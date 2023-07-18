class Question::NationalInsuranceNumberComponent::NationalInsuranceNumberComponentPreview < ViewComponent::Preview
  def national_insurance_number_field
    question = OpenStruct.new(national_insurance_number: "AB 123456 C",
                              answer_type: "national_insurance_number",
                              question_text: "What is your NI number?",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NationalInsuranceNumberComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def national_insurance_number_field_with_hint
    question = OpenStruct.new(national_insurance_number: "AB 123456 C",
                              answer_type: "national_insurance_number",
                              question_text: "What is your NI number?",
                              hint_text: "eg. AB 12 34 56 C",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::NationalInsuranceNumberComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end
end
