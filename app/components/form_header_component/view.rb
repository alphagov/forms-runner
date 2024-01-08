module FormHeaderComponent
  GOVUK_BASE_URL = "https://www.gov.uk/".freeze

  class View < ViewComponent::Base
    def initialize(current_context:, mode:, service_url_overide: :not_set, hosting_environment: HostingEnvironment)
      @current_context = current_context
      @mode = mode
      @service_url_overide = service_url_overide
      @hosting_environment = hosting_environment
      super
    end

    def call
      if @current_context.present?
        homepage_url = @mode.preview? ? Settings.forms_admin.base_url : GOVUK_BASE_URL

        govuk_header(service_name: @current_context.form.name,
                     homepage_url:,
                     service_url:,
                     classes: ["app-header", "app-header--#{@mode}"]) do |header|
          header.with_product_name(name: service_name_with_tag)
        end
      else
        govuk_header(homepage_url: GOVUK_BASE_URL, classes: ["app-header", "app-header--#{@mode}"]) do |header|
          header.with_product_name(name: service_name_with_tag)
        end
      end
    end

  private

    def service_name_with_tag
      govuk_tag(colour: colour_for_environment, text: environment_name).html_safe unless environment_name == I18n.t("environment_names.production")
    end

    def environment_name
      @hosting_environment.friendly_environment_name
    end

    def colour_for_environment
      case environment_name
      when "Local"
        "pink"
      when "Development"
        "green"
      when "Staging"
        "yellow"
      else
        "blue"
      end
    end

    def service_url
      if @service_url_overide == :not_set
        form_path(form_id: @current_context.form.id, form_slug: @current_context.form.form_slug)
      else
        @service_url_overide
      end
    end
  end
end
