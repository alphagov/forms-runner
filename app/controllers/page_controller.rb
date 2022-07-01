class PageController < ApplicationController
  before_action :fetch_pages

  def show
    changing_existing_answer
    back_link

    answer = get_stored_answer(@form.id, @page.id)
    question_klass = QuestionRegister.from_page(@page)
    @question = question_klass.new(answer)
  end

  def submit
    changing_existing_answer
    page_id = params.require(:page_id)
    @page = @pages.find { |p| p.id == page_id.to_i }

    question_klass = QuestionRegister.from_page(@page)
    question_params = question_params(question_klass)
    @question = question_klass.new(question_params)
    if @question.valid?
      store_answer(@form.id, @page.id, @question.serializable_hash)
      if @page.has_next? && !@changing_existing_answer
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
    page_id = params.require(:page_id)
    @page = @pages.find { |p| p.id == page_id.to_i }
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

  def store_answer(form_id, page_id, answer)
    session[:answers] ||= {}
    session[:answers][form_id.to_s] ||= {}
    session[:answers][form_id.to_s][page_id.to_s] = answer
  end

  def get_stored_answer(form_id, page_id)
    session.dig(:answers, form_id.to_s, page_id.to_s)
  end

  def question_params(question)
    params.require(:question).permit(*question.attribute_names)
  end
end
