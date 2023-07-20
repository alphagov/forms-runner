class Question::OrganisationNameComponent::OrganisationNameComponentPreview < ViewComponent::Preview
  def organisation_name_field
    question = OpenStruct.new(text: "Organisations R Us",
                              answer_type: "organisation_name",
                              question_text: "What is your company name?",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::OrganisationNameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def organisation_name_field_with_hint
    question = OpenStruct.new(text: "Organisations R Us",
                              answer_type: "organisation_name",
                              question_text: "What is your company name?",
                              hint_text: "As registered with Companies House",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})

    render(Question::OrganisationNameComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end
end
