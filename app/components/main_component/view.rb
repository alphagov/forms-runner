# frozen_string_literal: true

module MainComponent
  class View < ViewComponent::Base
    def initialize(mode:, is_question: false, is_component_preview: false)
      super
      @mode = mode
      @is_question = is_question
      @is_component_preview = is_component_preview
    end

    def call
      tag.main(class: "govuk-main-wrapper #{mode_class} #{is_question_class}", id: @is_component_preview ? nil : "main-content", role: "main") do
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
