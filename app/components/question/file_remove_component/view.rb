# frozen_string_literal: true

module Question::FileRemoveComponent
  class View < Question::Base
    def initialize(question:, mode:, remove_file_url:, remove_input:)
      @remove_file_url = remove_file_url
      @remove_input = remove_input
      super(form_builder: nil, question:, mode:)
    end
  end
end
