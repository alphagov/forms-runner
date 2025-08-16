module Forms
  class BaseController < ApplicationController
    prepend_before_action :check_available
    around_action :set_locale

    def redirect_to_friendly_url_start
      redirect_to form_page_path(params.require(:form_id), form.form_slug, form.start_page)
      LogEventService.log_form_start unless mode.preview?
    end

    rescue_from ActiveResource::ResourceNotFound, Flow::StepFactory::PageNotFoundError, RepeatableStep::AnswerIndexError do
      I18n.with_locale(locale) do
        render template: "errors/not_found", status: :not_found
      end
    end

    def error_repeat_submission
      @current_context = Flow::Context.new(form: form, store: session)
      render template: "errors/repeat_submission", locals: { form: }
    end

    def set_request_logging_attributes
      super
      CurrentRequestLoggingAttributes.form_name = form.name
      CurrentRequestLoggingAttributes.preview = mode.preview?
    end

    def form
      @form ||= Api::V1::FormSnapshotRepository.find_with_mode(id: params.require(:form_id), mode:)
    end

  private

    def archived_form
      Api::V1::FormSnapshotRepository.find_archived(id: params.require(:form_id))
    end

    def current_context
      @current_context ||= Flow::Context.new(form: form, store: session)
    end

    def mode
      @mode ||= Mode.new(params[:mode])
    end

    def default_url_options
      { mode: }
    end

    def check_available
      begin
        return if form.start_page && (mode.preview? || form.live?)
      rescue ActiveResource::ResourceNotFound
        form = archived_form
        return render template: "forms/archived/show", locals: { form_name: form.name }, status: :gone if form.present?
      end

      raise ActiveResource::ResourceNotFound, "Not Found"
    end

    def set_locale(&action)
      I18n.with_locale(locale, &action)
    end

    def locale
      return @form.language if @form.present? && @form.respond_to?(:language)

      I18n.default_locale
    end
  end
end
