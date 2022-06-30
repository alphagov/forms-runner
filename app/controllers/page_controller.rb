class PageController < ApplicationController
  before_action :fetch_pages

  def show
    changing_existing_answer
    back_link

    page_id = params.require(:page_id)
    @page = @pages.find { |p| p.id == page_id.to_i }
  end

  def submit
    changing_existing_answer
    page_id = params.require(:page_id)
    @page = @pages.find { |p| p.id == page_id.to_i }


    if @page.has_next? && !@changing_existing_answer
      redirect_to form_page_path(@form.id, @page.next)
    else
      redirect_to form_check_your_answers_path(@form.id)
    end
  end

private

  def fetch_pages
    @form = Form.find(params.require(:form_id))
    @pages = @form.pages
  end

  def changing_existing_answer
    @changing_existing_answer = ActiveModel::Type::Boolean.new.cast(params[:changing_existing_answer])
  end

  def back_link
    page_id = params.require(:page_id)
    previous_page = @pages.find do |p|
      next unless p.attributes["next"]

      p.next.to_i == page_id.to_i
    end
    if @changing_existing_answer
      @back_link = form_check_your_answers_path(@form.id)
    elsif previous_page
      @back_link = form_page_path(@form.id, previous_page.id)
    end
  end
end
