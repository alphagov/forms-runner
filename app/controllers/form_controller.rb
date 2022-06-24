class FormController < ApplicationController
  def show
    @form = Form.find(params.require(:id))
    if @form.start_page
      redirect_to form_page_path(params.require(:id), @form.start_page)
    end
  end

  def check_your_answers
    @form = Form.find(params.require(:form_id))
    @pages = @form.pages
    last_page = @pages.find { |p| !p.has_next? }
    @back_link = form_page_path(@form.id, last_page.id)
  end
end
