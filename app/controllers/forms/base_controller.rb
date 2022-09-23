module Forms
  class BaseController < ApplicationController
    def redirect_to_user_friendly_url
      redirect_to_friendly_url_start
    end

    def show
      redirect_to_friendly_url_start
    end

    rescue_from ActiveResource::ResourceNotFound do
      render template: "errors/not_found", status: :not_found
    end

  private

    def redirect_to_friendly_url_start
      # this will cleaned up in the PR which adds a guard to return 404 for all forms which either:
      # don't have a start page or
      # don't have a live_at date in the past outside of preview
      @form = Form.find(params.require(:form_id))
      if @form.start_page
        redirect_to form_page_path(params.require(:form_id), @form.form_slug, @form.start_page)
        EventLogger.log_form_event(Context.new(form: @form, store: session), request, "visit") unless preview?
      else
        raise ActiveResource::ResourceNotFound, "no start page"
      end
    end

    def current_context
      @current_context ||= Context.new(form: Form.find(params.require(:form_id)), store: session)
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
  end
end
