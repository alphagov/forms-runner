# frozen_string_literal: true

module Question::FileRemoveComponent
  class View < Question::Base
    def initialize(question:, extra_question_text_suffix:, remove_file_url:, remove_file_input:)
      @remove_file_url = remove_file_url
      @remove_file_input = remove_file_input
      super(form_builder: nil, question:, extra_question_text_suffix:)
    end
  end
end
