class FormController < ApplicationController
  def show
    @form = Form.find(params.require(:id))
    if @form.start_page
      redirect_to form_page_path(params.require(:id), @form.start_page)
      log_form_event(@form, request, "visit")
    end
  end

  def submitted
    @form = Form.find(params.require(:form_id))
  end
end
