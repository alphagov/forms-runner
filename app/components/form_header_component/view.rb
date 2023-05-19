module FormHeaderComponent
  class View < ViewComponent::Base
    def initialize(current_context:, mode:, service_url_overide: :not_set)
      @current_context = current_context
      @mode = mode
      @service_url_overide = service_url_overide
      super
    end

    def call
      if @current_context.present?
        govuk_header(service_name: @current_context.form.name,
                     homepage_url: "https://www.gov.uk/",
                     service_url:,
                     classes: "govuk-header--#{@mode}")
      else
        govuk_header(homepage_url: "https://www.gov.uk/")
      end
    end

  private

    def service_url
      if @service_url_overide == :not_set
        form_path(form_id: @current_context.form.id, form_slug: @current_context.form.form_slug)
      else
        @service_url_overide
      end
    end
  end
end
