module Forms
  class BaseController < ApplicationController

    rescue_from ActiveResource::ResourceNotFound do
      render template: "errors/not_found", status: :not_found
    end

    def redirect_to_user_friendly_url
      @form = Form.find(params.require(:form_id))
      redirect_to form_path(@form.id, @form.form_slug)
    end

    def show
      @form = Form.find(params.require(:form_id))
      if @form.start_page
        redirect_to form_page_path(params.require(:form_id), @form.form_slug, @form.start_page)
        unless preview?
          EventLogger.log_form_event(Context.new(form: @form, store: session), request, "visit")
        end
      end
    end

    private

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
