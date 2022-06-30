class FormController < ApplicationController
  def show
    @form = Form.find(params.require(:id))
    if @form.start_page
      redirect_to form_page_path(params.require(:id), @form.start_page)
    end
  end

  def check_your_answers
    @form = Form.find(params.require(:form_id))
    @answers = session.fetch(:answers, {}).fetch(@form.id.to_s, {})
    last_page = @form.pages.find { |p| !p.has_next? }
    @back_link = form_page_path(@form.id, last_page.id)
    @rows = check_your_answers_rows(@form, @answers)
  end

  def submit_answers
    @form = Form.find(params.require(:form_id))
    answers = session.fetch(:answers, {}).fetch(@form.id.to_s, {})
    submit_form(formatted_answers(@form, answers))
    logger.info session[:answers]
    clear_answers(@form)
    logger.info session[:answers]
    redirect_to :form_submitted
  end

  def submitted
    @form = Form.find(params.require(:form_id))
  end

private

  def submit_form(text)
    # in the controller for now but can be moved to service object, maybe use actionmailer fo easier testing?
    NotifyService.new.send_email(@form.submission_email, @form.name, text, Time.zone.now)
    # forms always submit corectly, to add error handling
    true
  end

  def clear_answers(form)
    session[:answers][form.id.to_s] = nil if session[:answers]
  end

  def check_your_answers_rows(form, answers = {})
    form.pages.map do |page|
      answer = answers[page.id.to_s]
      question = QuestionRegister.from_page(page).new(answer)
      {
        key: { text: page.question_text },
        value: { text: question.show_answer },
        actions: [{ href: form_page_url(form, page) }],
      }
    end
  end

  def formatted_answers(form, answers = {})
    form.pages.map { |page|
      answer = answers[page.id.to_s]
      question = QuestionRegister.from_page(page).new(answer)
      "#{page.question_text}: #{question.show_answer}"
    }.join("\n")
  end
end
