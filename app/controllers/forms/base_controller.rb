module Forms
  class BaseController < ApplicationController
    prepend_before_action :set_form
    around_action :set_locale

    def redirect_to_friendly_url_start
      redirect_to form_page_path(params.require(:form_id), @form.form_slug, @form.start_page)
      LogEventService.log_form_start unless mode.preview?
    end

    rescue_from ActiveResource::ResourceNotFound, RepeatableStep::AnswerIndexError do
      I18n.with_locale(locale) do
        render template: "errors/not_found", status: :not_found
      end
    end

    def error_repeat_submission
      @current_context = Flow::Context.new(form: @form, store: session)
      render template: "errors/repeat_submission", locals: { form: @form }
    end

    def set_request_logging_attributes
      super
      CurrentRequestLoggingAttributes.form_name = @form.name
      CurrentRequestLoggingAttributes.preview = mode.preview?

      # Add form-level attributes to OpenTelemetry span
      TelemetryService.set_request_attributes({
        "form.name" => @form.name,
        "form.slug" => @form.form_slug,
        "mode.type" => mode.mode,
        "mode.preview" => mode.preview?,
      })
    end

  private

    def current_context
      @current_context ||= Flow::Context.new(form: @form, store: session)
    end

    def mode
      @mode ||= Mode.new(params[:mode])
    end

    def default_url_options
      { mode:, locale: locale_param }
    end

    def set_form
      begin
        form_id = params.require(:form_id)
        @form = Api::V2::FormDocumentRepository.find_with_mode(form_id:, mode:, language: locale)
      rescue ActiveResource::ResourceNotFound
        archived_form = Api::V2::FormDocumentRepository.find(form_id:, tag: :archived)
        return render template: "forms/archived/show", locals: { form_name: archived_form.name }, status: :not_found if archived_form.present?
      end

      raise ActiveResource::ResourceNotFound, "Not Found" unless @form.start_page
    end
  end
end
