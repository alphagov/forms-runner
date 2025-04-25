# frozen_string_literal: true

module Question::FileReviewComponent
  class View < Question::Base
    def initialize(question:, extra_question_text_suffix:, remove_file_confirmation_url:)
      @remove_file_confirmation_url = remove_file_confirmation_url
      super(form_builder: nil, question:, extra_question_text_suffix:)
    end
  end
end
