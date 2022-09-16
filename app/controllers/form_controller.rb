class FormController < ApplicationController
  rescue_from ActiveResource::ResourceNotFound do
    render template: "errors/not_found", status: :not_found
  end

  def show
    @form = Form.find(params.require(:id))
    set_privacy_policy_url
    if @form.start_page
      redirect_to form_page_path(params.require(:id), @form.start_page)
      unless preview?
        EventLogger.log_form_event(Context.new(form: @form, store: session), request, "visit")
      end
    end
  end

  def submitted
    @form = Form.find(params.require(:form_id))
    set_privacy_policy_url
  end

private

  def set_privacy_policy_url
    @privacy_policy_url = @form.privacy_policy_url
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
