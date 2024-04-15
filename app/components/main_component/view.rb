# frozen_string_literal: true

module MainComponent
  class View < ViewComponent::Base
    def initialize(is_component_preview: false)
      super
      @is_component_preview = is_component_preview
    end

    def call
      tag.main(class: "govuk-main-wrapper", id: @is_component_preview ? nil : "main-content", role: "main") do
        content
      end
    end
  end
end
