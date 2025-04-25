class Question::FileReviewComponent::FileReviewComponentPreview < ViewComponent::Preview
  def file_review
    question = OpenStruct.new(answer_type: "file",
                              original_filename: "a_file.png",
                              question_text_with_optional_suffix: "Upload your photo",
                              answer_settings: nil)
    render(Question::FileReviewComponent::View.new(question:, extra_question_text_suffix: "", remove_file_confirmation_url: "/remove_file_confirmation"))
  end

  def file_review_with_hint
    question = OpenStruct.new(answer_type: "file",
                              original_filename: "a_file.png",
                              question_text_with_optional_suffix: "Upload your photo",
                              hint_text: "Make sure your face is clearly visible",
                              answer_settings: nil)
    render(Question::FileReviewComponent::View.new(question:, extra_question_text_suffix: "", remove_file_confirmation_url: "/remove_file_confirmation"))
  end
end
