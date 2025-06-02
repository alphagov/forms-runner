module FooterComponent
  class View < ViewComponent::Base
    include Rails.application.routes.url_helpers

    def initialize(mode:, current_form:)
      @mode = mode
      @current_form = current_form
      super
    end

    def meta_links
      links = {
        I18n.t("footer.accessibility_statement") => accessibility_statement_path(locale:),
        I18n.t("footer.cookies") => cookies_path(locale:),
      }

      if @current_form.present?
        links[I18n.t("footer.privacy_policy")] = form_privacy_path(
          mode: @mode, form_id: @current_form.id, form_slug: @current_form.form_slug,
        )
      end

      links
    end

  private

    def locale
      I18n.locale if I18n.locale != I18n.default_locale
    end
  end
end
