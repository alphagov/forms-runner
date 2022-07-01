class FormController < ApplicationController
  def show
    @form = Form.find(params.require(:id))
    if @form.start_page
      redirect_to form_page_path(params.require(:id), @form.start_page)
    end
  end

  def check_your_answers
    @form = Form.find(params.require(:form_id))
    journey_context = JourneyContext.new(session, @form)
    @answers = journey_context.answers
    last_page = @form.pages.find { |p| !p.has_next? }
    @back_link = form_page_path(@form.id, last_page.id)
    @rows = check_your_answers_rows(@form, @answers)
  end

  def submit_answers
    @form = Form.find(params.require(:form_id))
    journey_context = JourneyContext.new(session, @form)
    answers = journey_context.answers
    submit_form(formatted_answers(@form, answers))
    journey_context.clear_answers
    redirect_to :form_submitted
  end

  def submitted
    @form = Form.find(params.require(:form_id))
  end

private

  def submit_form(text)
    # in the controller for now but can be moved to service object, maybe use actionmailer fo easier testing?
    logger.info "Submitted: #{text}"
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
      question_name = page.question_short_name.presence || page.question_text
      question = QuestionRegister.from_page(page).new(answer)
      {
        key: { text: question_name },
        value: { text: question.show_answer },
        actions: [{ href: change_form_page_path(form, page), visually_hidden_text: question_name }],
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
