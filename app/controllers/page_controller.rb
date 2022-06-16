class PageController < ApplicationController
  def show
    form_id = params.require(:form_id)
    page_id = params.require(:id)
    @page = Page.find(page_id, params: {form_id: form_id})
  end
end
