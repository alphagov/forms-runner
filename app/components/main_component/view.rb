# frozen_string_literal: true

module MainComponent
  class View < ViewComponent::Base
    def initialize(mode:, is_question: false)
      super
      @mode = mode
      @is_question = is_question
    end

    def call
      tag.main(class: "govuk-main-wrapper #{mode_class} #{is_question_class}", id: "main-content", role: "main") do
        content
      end
    end

  private

    def mode_class
      "main--#{@mode}" if @mode.present?
    end

    def is_question_class
      "main--question" if @is_question
    end
  end
end
