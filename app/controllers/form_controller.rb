class FormController < ApplicationController
  def show
    form = Form.find(params.require(:id))
    redirect_to form_page_path(form_id: params.require(:id), id: form.start_page)
  end
end
