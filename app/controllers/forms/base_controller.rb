module Forms
  class BaseController < ApplicationController
    before_action :check_available

    def redirect_to_friendly_url_start
      redirect_to form_page_path(params.require(:form_id), current_form.form_slug, current_form.start_page)
      EventLogger.log_form_event(Context.new(form: current_form, store: session), request, "visit") unless preview?
    end

    rescue_from ActiveResource::ResourceNotFound do
      render template: "errors/not_found", status: :not_found
    end

    def error_repeat_submission
      @current_context = Context.new(form: current_form, store: session)
      render template: "errors/repeat_submission", locals: { current_form: }
    end

  private

    def current_form
      @current_form ||= fetch_form
    end

    def current_context
      @current_context ||= Context.new(form: current_form, store: session)
    end

    def live
      @live ||= !preview?
    end

    def preview?
      preview_draft? || preview_live?
    end

    def preview_draft?
      mode == "preview-draft"
    end

    def preview_live?
      mode == "preview-live"
    end

    def fetch_form
      form_id = params.require(:form_id)

      if preview_draft?
        Form.find_draft(form_id)
      elsif preview_live?
        Form.find_live(form_id)
      elsif live
        Form.find_live(form_id)
      end
    end

    def mode
      params[:mode]
    end

    def default_url_options
      { mode: }
    end

    def check_available
      return if current_form.start_page && (preview? || current_form.live?)

      raise ActiveResource::ResourceNotFound, "Not Found"
    end
  end
end
