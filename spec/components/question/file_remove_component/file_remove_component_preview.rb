class Question::FileRemoveComponent::FileRemoveComponentPreview < ViewComponent::Preview
  def file_remove
    question = OpenStruct.new(answer_type: "file",
                              original_filename: "a_file.png",
                              question_text_with_optional_suffix: "Upload your photo",
                              answer_settings: nil)
    render(Question::FileRemoveComponent::View.new(question:, extra_question_text_suffix: "", remove_file_url: "/remove_file", remove_input: RemoveInput.new))
  end

  def file_remove_with_hint
    question = OpenStruct.new(answer_type: "file",
                              original_filename: "a_file.png",
                              question_text_with_optional_suffix: "Upload your photo",
                              hint_text: "Make sure your face is clearly visible",
                              answer_settings: nil)
    render(Question::FileRemoveComponent::View.new(question:, extra_question_text_suffix: "", remove_file_url: "/remove_file", remove_input: RemoveInput.new))
  end
end
