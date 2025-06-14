module Forms
  class BaseController < ApplicationController
    before_action :check_available
    around_action :set_locale

    def redirect_to_friendly_url_start
      redirect_to form_page_path(params.require(:form_id), current_form.form_slug, current_form.start_page)
      LogEventService.log_form_start unless mode.preview?
    end

    rescue_from ActiveResource::ResourceNotFound, Flow::StepFactory::PageNotFoundError, RepeatableStep::AnswerIndexError do
      I18n.with_locale(locale) do
        render template: "errors/not_found", status: :not_found
      end
    end

    def error_repeat_submission
      @current_context = Flow::Context.new(form: current_form, store: session)
      render template: "errors/repeat_submission", locals: { current_form: }
    end

    def set_request_logging_attributes
      super
      CurrentRequestLoggingAttributes.form_name = current_form.name
      CurrentRequestLoggingAttributes.preview = mode.preview?
    end

  private

    def current_form
      @current_form ||= Api::V1::FormSnapshotRepository.find_with_mode(id: params.require(:form_id), mode:)
    end

    def current_context
      @current_context ||= Flow::Context.new(form: current_form, store: session)
    end

    def mode
      @mode ||= Mode.new(params[:mode])
    end

    def default_url_options
      { mode: }
    end

    def check_available
      return if current_form.start_page && (mode.preview? || current_form.live?)

      raise ActiveResource::ResourceNotFound, "Not Found"
    end

    def set_locale(&action)
      I18n.with_locale(locale, &action)
    end

    def locale
      return @current_form.language if @current_form.present? && @current_form.respond_to?(:language)

      I18n.default_locale
    end
  end
end
