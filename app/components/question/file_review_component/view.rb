# frozen_string_literal: true

module Question::FileReviewComponent
  class View < Question::Base
    def initialize(question:, mode:, remove_file_confirmation_url:)
      @remove_file_confirmation_url = remove_file_confirmation_url
      super(form_builder: nil, question:, mode:)
    end
  end
end
