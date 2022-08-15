class PageController < ApplicationController
  before_action :fetch_pages

  def show
    changing_existing_answer
    back_link

    # extract an answer from the sesssion, test it to make sure it's still
    # valid
    form_context = FormContext.new(session, @form)
    answer = form_context.get_stored_answer(@page)
    question_klass = QuestionRegister.from_page(@page)
    begin
      @question = question_klass.new(answer)
    rescue ActiveModel::UnknownAttributeError
      @question = question_klass.new
    end

    @question = question_klass.new unless @question&.valid?
  end

  def save
    changing_existing_answer
    page_id = params.require(:page_id)
    @page = @pages.find { |p| p.id == page_id.to_i }

    question_klass = QuestionRegister.from_page(@page)
    question_params = question_params(question_klass)
    @question = question_klass.new(question_params)
    form_context = FormContext.new(session, @form)
    if @question.valid?
      form_context.store_answer(@page, @question.serializable_hash)
      log_page_save(@form, @page, request, changing_existing_answer)
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

  def question_params(question)
    params.require(:question).permit(*question.attribute_names)
  end

  def is_starting_form(form, page)
    form.start_page == page.id
  end

  def log_page_save(form, page, request, changing_existing_answer)
    item_to_log = {
      url: request&.url,
      method: request&.method,
      form: form&.name,
      question_text: page&.question_text,
      user_agent: request&.user_agent,
    }

    log_event = if changing_existing_answer
                  "change_answer_page_save"
                elsif is_starting_form(form, page)
                  "first_page_save"
                else
                  "page_save"
                end

    EventLogger.log(log_event, item_to_log)
  end
end
