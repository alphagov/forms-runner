# frozen_string_literal: true

module SupportDetailsComponent
  class View < ViewComponent::Base
    def initialize(support_details)
      super
      @support_details = support_details
    end

    def render?
      [@support_details.email, @support_details.phone].any?(&:present?) || [@support_details.url, @support_details.url_text].all?(&:present?)
    end
  end
end
