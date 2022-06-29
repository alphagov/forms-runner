class PageController < ApplicationController
  before_action :fetch_pages

  def show
    back_link

    page_id = params.require(:page_id)
    @page = @pages.find { |p| p.id == page_id.to_i }
    answer = get_stored_answer(@form.id, page_id)
    @question = @page.question.new(answer)
  end

  def submit
    page_id = params.require(:page_id)
    @page = @pages.find { |p| p.id == page_id.to_i }
    @question = @page.question.new(params.permit(question: {})[:question])
    if @question.valid?
      store_answer(@form.id, page_id, @question.serializable_hash)
      if @page.has_next?
        redirect_to form_page_path(@form.id, @page.next)
      else
        redirect_to form_check_your_answers_path(@form.id)
      end
    else
      render :show
    end
  end

private

  def fetch_pages
    @form = Form.find(params.require(:form_id))
    @pages = @form.pages
  end

  def back_link
    page_id = params.require(:page_id)
    previous_page = @pages.find do |p|
      next unless p.attributes["next"]

      p.next.to_i == page_id.to_i
    end

    if previous_page
      @back_link = form_page_path(@form.id, previous_page.id)
    end
  end

  def store_answer(form_id, page_id, answer)
    session[:answers] ||= {}
    session[:answers][form_id.to_s] ||= {}
    session[:answers][form_id.to_s][page_id] = answer
    logger.info "Saving \"#{answer}\" under [#{form_id}][#{page_id}]"
  end

  def get_stored_answer(form_id, page_id)
    logger.info "session \"#{session[:answers]}\""
    answer = session.dig(:answers, form_id.to_s, page_id)
    logger.info "retrieving \"#{answer}\" from [#{form_id}][#{page_id}]"
    answer
  end
end
