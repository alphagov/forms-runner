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

    def session_expired
      current_context
      render "errors/session_expired", locals: { current_form: }
    end

  private

    def set_session_cookie
      session[:datetime_started] = Time.zone.now.utc.iso8601 if session[:datetime_started].blank?
    end

    def check_session_expiry
      set_session_cookie if session[:datetime_started].blank?

      if Time.zone.now.to_i - Time.zone.parse(session[:datetime_started]).to_i >= 20.hours
        redirect_to error_session_expired_path(current_form.id)
      end
    end

    def current_form
      @current_form ||= Form.find_live(params.require(:form_id))
    end

    def current_context
      @current_context ||= Context.new(form: current_form, store: session)
    end

    def preview?
      params[:mode] == "preview-form"
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
