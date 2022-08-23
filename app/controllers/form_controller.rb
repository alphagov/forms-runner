class FormController < ApplicationController
  def show
    @form = Form.find(params.require(:id))
    set_privacy_policy_url
    if @form.start_page
      redirect_to form_page_path(params.require(:id), @form.start_page)
      EventLogger.log_form_event(Context.new(form: @form, store: session), request, "visit")
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
end
