module FormHeaderComponent
  class View < ViewComponent::Base
    def initialize(current_context:, mode:)
      @current_context = current_context
      @mode = mode
    end

    def call
      if @current_context.present?
        govuk_header(service_name: @current_context.form_name,
                     homepage_url: "https://www.gov.uk/",
                     service_url: form_path(form_id: @current_context.form, form_slug: @current_context.form_slug),
                     classes: 'govuk-header' + "--#{@mode}")
      else
        govuk_header(homepage_url: "https://www.gov.uk/")
      end
    end
  end
end
