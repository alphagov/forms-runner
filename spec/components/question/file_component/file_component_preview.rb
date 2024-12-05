class Question::FileComponent::FileComponentPreview < ViewComponent::Preview
  def file_field
    question = OpenStruct.new(answer_type: "file",
                              question_text_with_optional_suffix: "Upload your photo",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
    render(Question::FileComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end

  def file_field_with_hint
    question = OpenStruct.new(answer_type: "file",
                              question_text_with_optional_suffix: "Upload your photo",
                              hint_text: "Make sure your face is clearly visible",
                              answer_settings: nil)
    form_builder = GOVUKDesignSystemFormBuilder::FormBuilder.new(:form, question,
                                                                 ActionView::Base.new(ActionView::LookupContext.new(nil), {}, nil), {})
    render(Question::FileComponent::View.new(form_builder:, question:, extra_question_text_suffix: ""))
  end
end
